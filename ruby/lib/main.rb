require 'tadb'

class Module
    def has_one type, description
        # TODO check tipos
        extend ORM::PersistibleModule
        initialize_persistence
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name } 
        @persistible_attrs << {name: attr_name, type: type} # sería como la metadata de @table
        attr_accessor attr_name
    end
end 


module ORM
    module PersistibleObject
        def save!
            if not @id
                define_singleton_method(:id) { @id } # en la singleton class porque sólo tienen que tenerlo los objetos a los que se les mandó save!
                self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
                (self.class.instance_variable_get :@persistible_attrs).each do |attr|
                    attr_value = send attr[:name]
                    if attr_value != nil then self_hashed[attr[:name]] = attr_value end # para no romper en caso de que un atributo esté vacío, por ahora
                end
                @id = self.class.table_insert self_hashed
                return # para no devolver el id afuera
            end
            forget! # TADB sólo permite insertar o borrar, no hay update. así que...
            save!
        end

        def refresh!
            (self.class.table_find_by_id @id).each do |attr_name, attr_value|
                if attr_name != :id # necesito hacer esto porque :id no tiene setter; no hago un reject de antemano porque sería menos performante creo
                    send (attr_name.to_s + '=').to_sym, attr_value
                end
            end
        end

        def forget!
            self.class.table_delete_by_id @id
            singleton_class.remove_method :id
            @id = nil # si no hago esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! se rompe 
        end
    end


    module PersistibleModule
        def initialize_persistence
            if not @table
                include PersistibleObject
                @persistible_attrs = []
                @table = TADB::DB.table(name)
            end
        end

        def table_insert hashed_instance
            @table.insert(hashed_instance)
        end      

        def table_find_by_id id
            @table.entries.detect { |entry| entry[:id] == id }
        end

        def table_delete_by_id id
            @table.delete id
        end

        def all_instances # creo cada instancia, le seteo un id válido y le doy refresh. con eso, armo la lista que devuelvo 
            instances = []
            @table.entries.each do |entry|
                instance = new
                instance.define_singleton_method(:id) { @id }
                instance.define_singleton_method(:id=) { |id| @id = id }
                instance.id=entry[:id]
                instance.singleton_class.remove_method(:id=) # este método se lo damos sólo para setearle el id acá adentro
                instance.refresh!
                instances << instance
            end
            return instances
        end
    end
end

# para testear a manopla
module CosasTesting
    class A
        has_one String, named: :coso
        has_one Numeric, named: :coso
    end
end
