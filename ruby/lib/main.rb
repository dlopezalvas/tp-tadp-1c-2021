require 'tadb'


class Module
    def ORM_add_persistible_attr type, description, is_multiple
        if type.ancestors.include? ORM::PersistibleObject
            type.send :ORM_add_deletion_observer, self
        end
        if not @table
            extend ORM::PersistibleModule # así el módulo/clase soporta persistencia (tiene tabla, atributos persistibles, etc.)
            prepend ORM::PersistibleObject # para que los objetos tengan el comportamiento de persistencia
            @deletion_observers = []
            @persistible_attrs = [{name: :id, type: String, multiple: false}]
            @table = TADB::DB.table(name)
        end
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name } 
        @persistible_attrs << {name: attr_name, type: type, multiple: is_multiple} # @persistible_attrs sería como la metadata de la @table del módulo
        attr_accessor attr_name # define getters+setters para los objetos
    end

    def has_one type, description
        ORM_add_persistible_attr type, description, false
    end

    def has_many type, description
        ORM_add_persistible_attr type, description, true
    end

    private :ORM_add_persistible_attr
end 


module ORM # a las cosas de acá se puede acceder a través de ORM::<algo>; la idea es no contaminar el namespace
    module PersistibleObject # esto es sólo para objetos; todo lo estático está en PersistibleModule
        def initialize *args
            ((self.class.instance_variable_get :@persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                send (attr[:name].to_s + '=').to_sym, []
            end
            super *args
        end

        def save!
            if @id 
                self.class.send :ORM_delete_entry, @id
            else    
                define_singleton_method(:id) { @id }
            end
            self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
            ((self.class.instance_variable_get :@persistible_attrs).reject { |attr| attr[:multiple] }).each do |attr|
                attr_value = send attr[:name]
                if not attr_value == nil
                    if attr[:type].ancestors.include? PersistibleObject # TODO abstraer?
                        self_hashed[attr[:name]] = attr_value.save!
                    else
                        self_hashed[attr[:name]] = attr_value
                    end
                end
            end
            @id = self.class.send :ORM_insert, self_hashed
            ((self.class.instance_variable_get :@persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                id_pair_hashed = {}
                id_pair_hashed[('id_' + self.class.name).to_sym] = @id
                (send attr[:name]).each do |elem|
                    id_pair_hashed[('id_' + attr[:name].to_s).to_sym] = elem.save!
                    (attr_table attr[:name]).insert id_pair_hashed
                end
            end
            return @id
        end

        def refresh!
            exception_if_no_id
            entry = self.class.send :ORM_get_entry, @id
            ((self.class.instance_variable_get :@persistible_attrs).reject { |attr| attr[:multiple] or attr[:name] == :id}).each do |attr| # TODO abstraer
                if attr[:type].ancestors.include? PersistibleObject
                    attr_final_value = (attr[:type].find_by_id entry[attr[:name]])[0]
                else
                    attr_final_value = entry[attr[:name]]
                end
                send (attr[:name].to_s + '=').to_sym, attr_final_value # seteo cada atributo con el valor dado por la entry de la tabla
            end
            ((self.class.instance_variable_get :@persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                matching_entries = ((attr_table attr[:name]).entries.select { |entry| entry[('id_' + self.class.name).to_sym] == @id })
                elem_enum = matching_entries.map do |entry|
                    (attr[:type].find_by_id entry[('id_' + attr[:name].to_s).to_sym])[0]
                end
                send (attr[:name].to_s + '=').to_sym, elem_enum.to_a
            end
            self
        end

        # TODO el forget tiene que borrar toda referencia al id en otras tablas!!!
        def forget! # se asume que no cascadea
            exception_if_no_id
            self.class.send :ORM_notify_deletion, @id
            self.class.send :ORM_delete_entry, @id
            singleton_class.remove_method :id
            @id = nil # si no hago esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! puede romper
        end

        def attr_table attr_name_symbol 
            TADB::DB.table(self.class.name + '__' + attr_name_symbol.to_s)
        end

        def exception_if_no_id
            if not @id then raise 'this instance is not persisted' end # TODO armar excepciones decentes
        end

        private :exception_if_no_id
    end


    module PersistibleModule # define exclusivamente lo estático; es necesaria la distinción por la diferencia entre include y extend
        def ORM_insert hashed_instance 
            @table.insert(hashed_instance)
        end      

        def ORM_get_entry id
            @table.entries.detect { |entry| entry[:id] == id }
        end

        def ORM_delete_entry id
            @table.delete id
        end

        def ORM_notify_deletion id
            @deletion_observers.each do |observer|
                observer.send :ORM_wipe_references_to, self, id
            end
        end

        def ORM_wipe_references_to type, id
            (@persistible_attrs.select { |attr| attr[:type] == type }).each do |attr|
                if attr[:multiple]
                    # TODO
                else
                    intances_to_update = send ('find_by_' + attr[:name].to_s).to_sym, id
                    intances_to_update.each do |instance|
                        # TODO
                    end
                end
            end
        end

        def ORM_add_deletion_observer a_class
            @deletion_observers << a_class
        end

        def all_instances 
            instantiate @table.entries
        end

        def method_missing symbol, *args, &block # para tratar con el requerimiento de find_by_<what>
            prefix = 'find_by_'
            query_attr = @persistible_attrs.detect { |attr| attr[:name].to_s == symbol.to_s[(prefix.length)..-1] } # buscamos el campo según el cual se filtra en la query
            if query_attr and symbol.to_s.start_with? prefix # si el campo existe y el prefijo es el correcto:
                # TODO no se está contemplando comparar por id para los atributos persistibles referenciados
                instantiate @table.entries.select { |entry| entry[query_attr[:name]] == args[0] } # se instancian los que cumplen la condición
            else
                super # si no matchea, continúa el method lookup
            end
        end

        def instantiate entries # dada una lista de entries, devuelve la lista de instancias correspondientes
            entries.map do |entry|
                instance = new
                instance.define_singleton_method(:id) { @id }
                instance.define_singleton_method(:id=) { |id| @id = id }
                instance.id = entry[:id]
                instance.singleton_class.remove_method(:id=) # este método se lo dábamos sólo para setearle el id acá adentro
                instance.refresh! # TODO teniendo el id bien, refresh trae el resto de los datos (para no repetir lógica); no es muy performante igual porque el refresh implica una búsqueda en la tabla cuando la información ya la tenemos en la entry. habría que optimizar sin repetir lógica
            end 
        end

        private :instantiate, :ORM_insert, :ORM_get_entry, :ORM_delete_entry, :ORM_notify_deletion, :ORM_wipe_references_to, :ORM_add_deletion_observer
    end
end


# para testear a manopla
module CosasTesting
    class DNI
        has_one Numeric, named: :number
    end

    class Grade
        has_one Numeric, named: :value
    end

    class Student
        has_one String, named: :full_name
        has_one DNI, named: :dni
        has_many Grade, named: :grades
    end
end

