require 'tadb'


class Module
    def has_one type, description
        extend ORM::PersistibleModule # así el módulo/clase soporta persistencia (tiene tabla, atributos persistibles, etc.)
        initialize_persistence
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name } 
        @persistible_attrs << {name: attr_name, type: type} # @persistible_attrs sería como la metadata de la @table del módulo
        attr_accessor attr_name # define getters+setters para los objetos
    end
end 


module ORM # a las cosas de acá se puede acceder a través de ORM::<algo>; la idea es no contaminar el namespace
    module PersistibleObject # esto es sólo para objetos; todo lo estático está en PersistibleModule
        def save!
            if not @id
                define_singleton_method(:id) { @id } # en la singleton class porque sólo tienen que tenerlo los objetos a los que se les mandó save!
                self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
                (self.class.instance_variable_get :@persistible_attrs).each do |attr|
                    attr_value = send attr[:name]
                    if attr_value != nil then self_hashed[attr[:name]] = attr_value end # para no romper en caso de que un atributo esté en nil; las tablas no aceptan nil
                end
                @id = self.class.table_insert self_hashed
                return # para no devolver el id
            end
            forget! # TADB sólo permite insertar o borrar, no hay update. así que...
            save! # así entra en el if de arriba y se persiste con un nuevo id
        end

        def refresh!
            (self.class.table_find_by_id @id).each do |attr_name, attr_value|
                if attr_name != :id # necesito hacer esto porque :id no tiene setter; no hago un reject de antemano porque sería menos performante creo
                    send (attr_name.to_s + '=').to_sym, attr_value # seteo cada atributo con el valor dado por la entry de la tabla
                end
            end
        end

        def forget!
            self.class.table_delete_by_id @id
            singleton_class.remove_method :id
            @id = nil # si no hago esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! se rompe 
        end
    end


    module PersistibleModule # define exclusivamente lo estático; es necesaria la distinción por la diferencia entre include y extend
        def initialize_persistence # esto no sé si es necesario abstraer pero bueno
            if not @table
                include PersistibleObject # para que los objetos tengan el comportamiento de persistencia
                @persistible_attrs = []
                @table = TADB::DB.table(name)
            end
        end

        # estos métodos table_* no sé si no estarán contaminando la interfaz. quizás sea bueno ocultarlos de alguna manera. a estos métodos los llaman los objetos cuando hacen save!, refresh!, etc.
        def table_insert hashed_instance 
            @table.insert(hashed_instance)
        end      

        def table_find_by_id id
            @table.entries.detect { |entry| entry[:id] == id }
        end

        def table_delete_by_id id
            @table.delete id
        end

        def all_instances 
            instantiate @table.entries
        end

        def method_missing symbol, *args, &block # para tratar con el requerimiento de find_by_<what>
            prefix = 'find_by_'
            requested_attr = @persistible_attrs.detect { |attr| attr[:name].to_s == symbol.to_s[(prefix.length)..-1] } # buscamos el campo según el cual se filtra en la query
            if requested_attr and symbol.to_s.start_with? prefix # si el campo existe y el prefijo es el correcto:
                instantiate @table.entries.select { |entry| entry[requested_attr[:name]] == args[0] } # se instancian los que cumplen la condición
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
                instance
            end 
        end

        private :instantiate
    end
end


# para testear a manopla
module CosasTesting
    class A
        has_one String, named: :coso
        has_one Numeric, named: :coso
    end
end
