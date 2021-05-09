require 'tadb'


class Module
    def has_one type, description
        if not @table
            extend ORM::PersistibleModule # así el módulo/clase soporta persistencia (tiene tabla, atributos persistibles, etc.)
            include ORM::PersistibleObject # para que los objetos tengan el comportamiento de persistencia
            @persistible_attrs = [{name: :id, type: String}]
            @table = TADB::DB.table(name)
        end
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name } 
        @persistible_attrs << {name: attr_name, type: type} # @persistible_attrs sería como la metadata de la @table del módulo
        attr_accessor attr_name # define getters+setters para los objetos
    end
end 


module ORM # a las cosas de acá se puede acceder a través de ORM::<algo>; la idea es no contaminar el namespace
    module PersistibleObject # esto es sólo para objetos; todo lo estático está en PersistibleModule
        def save!
            if @id 
                self.class.send :ORM_delete_entry, @id
            else    
                define_singleton_method(:id) { @id }
            end
            self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
            (self.class.instance_variable_get :@persistible_attrs).each do |attr|
                attr_value = send attr[:name]
                if not attr_value == nil
                    if attr[:type].ancestors.include? PersistibleObject # TODO abstraer?
                        attr_final_value = attr_value.save!
                    else
                        attr_final_value = attr_value
                    end
                    self_hashed[attr[:name]] = attr_final_value
                end
            end
            @id = self.class.send :ORM_insert, self_hashed
        end

        def refresh!
            exception_if_no_id
            (self.class.send :ORM_get_entry, @id).each do |attr_name, attr_value|
                if attr_name != :id # necesito hacer esto porque :id no tiene setter; no hago un reject de antemano porque sería menos performante creo
                    attr_type = ((self.class.instance_variable_get :@persistible_attrs).detect{ |attr| attr[:name] == attr_name })[:type] # TODO abstraer
                    if attr_type.singleton_class.ancestors.include? PersistibleModule # TODO abstraer?
                        attr_final_value = (attr_type.find_by_id attr_value)[0] # TODO ojo porque lo estamos buscando desde la tabla; podría haber varios objetos distintos para la misma entrada de la tabla
                    else
                        attr_final_value = attr_value
                    end
                    send (attr_name.to_s + '=').to_sym, attr_final_value # seteo cada atributo con el valor dado por la entry de la tabla
                end
            end
            self
        end

        def forget! # se asume que no cascadea
            exception_if_no_id
            self.class.send :ORM_delete_entry, @id
            singleton_class.remove_method :id
            @id = nil # si no hago esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! puede romper
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

        def all_instances 
            instantiate @table.entries
        end

        def method_missing symbol, *args, &block # para tratar con el requerimiento de find_by_<what>
            prefix = 'find_by_'
            query_attr = @persistible_attrs.detect { |attr| attr[:name].to_s == symbol.to_s[(prefix.length)..-1] } # buscamos el campo según el cual se filtra en la query
            if query_attr and symbol.to_s.start_with? prefix # si el campo existe y el prefijo es el correcto:
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

        private :instantiate, :ORM_insert, :ORM_get_entry, :ORM_delete_entry
    end
end


# para testear a manopla
module CosasTesting
    class Grade
        has_one Numeric, named: :value
    end

    class Student
        has_one String, named: :full_name
        has_one Grade, named: :grade
    end
end

