require 'tadb'

class Module
    def has_one type, desc
        selector = desc[:named] # selector es el nombre de la columna
        # TODO check tipos
        create_table # si la clase no tiene tabla, la crea
        attr_accessor selector
        if not @persistent_attrs # seguimiento de los atributos a persistir
            @persistent_attrs = []
        @persistent_attrs << selector
        end
    end

    def table_insert hashed_instance # pongo esta logica acá porque la tabla es de la clase
        @table.insert(hashed_instance)
    end

    def table_find_by_id id
        @table.entries.detect do |entry|
            entry[:id] == id
        end
    end

    def table_delete_by_id id
        @table.delete id
    end

    private
    def create_table
        if not @table
            include Persistent # si tiene tabla, necesita comportamiento de persistencia
            @table = TADB::DB.table(name)
        end
    end
end 

module Persistent
    def save!
        if not @id
            define_singleton_method :id do # lo pongo como singleton porque no todos los objetos persistentes tienen id hasta el primer save!
                @id
            end
            self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
            (self.class.instance_variable_get :@persistent_attrs).each do |selector|
                self_hashed[selector] = self.send selector # por cada atributo a persistir, lo incluyo en el hash que mando a insertar a la tabla
            end
            @id = self.class.table_insert self_hashed
        end
    end

    def refresh!
        (self.class.table_find_by_id @id).each do |attr_name, attr_value|
            if attr_name != :id
                self.send (attr_name.to_s + '=').to_sym, attr_value
            end
        end
    end

    def forget!
        self.class.table_delete_by_id @id
        @id = nil
        singleton_class.remove_method :id
        return
    end
end

# cosas de prueba
class B
    has_one String, named: :repe
    # has_one String, named: :repe
end
