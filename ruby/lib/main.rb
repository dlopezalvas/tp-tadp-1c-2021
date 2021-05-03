require 'tadb'


class Module
    def has_one type, description
        # TODO check tipos
        extend PersistibleModule
        initialize_persistence
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name } 
        @persistible_attrs << {name: attr_name, type: type} # sería como la metadata de @table
        attr_accessor attr_name
    end
end 


module PersistibleObject
    def save!
        if not @id
            define_singleton_method(:id) { @id } # en la singleton class porque sólo tienen que tenerlo los objetos a los que se les mandó save!
            self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
            (self.class.instance_variable_get :@persistible_attrs).each do |attr|
                selector = attr[:name]
                self_hashed[selector] = self.send selector # incluyo cada atributo a persistir en el hash que mando a insertar a la tabla
            end
            @id = self.class.table_insert self_hashed
        else
            # TODO pensar cómo conviene hacer updates (por el tema del id autogenerado)
        end
    end

    def refresh!
        (self.class.table_find_by_id @id).each do |attr_name, attr_value|
            if attr_name != :id # necesito hacer esto porque :id no tiene setter; no hago un reject de antemano porque sería menos performante creo
                self.send (attr_name.to_s + '=').to_sym, attr_value
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
end


