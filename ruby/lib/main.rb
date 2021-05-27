require 'tadb'

# TODO abstraer transformaciones de símbolos
# TODO abstraer todo lo posible juas

class Module

    def ORM_add_persistible_attr type, description, is_multiple:
        if type.is_a? ORM::PersistibleModule # TODO y si ese type se hace persistible más adelante?
            type.send :ORM_add_deletion_observer, self
        end
        if not @persistible_attrs
            if self.class == Class
                extend ORM::PersistibleClass
                prepend ORM::PersistibleObject # para que los objetos tengan el comportamiento de persistencia; es prepend para poder agregarle comportamiento al constructor
                @table = TADB::DB.table(name)
            else
                extend ORM::PersistibleModule
            end
            @descendants = []
            @deletion_observers = [] # tiene las clases a las que hay que notificar borrados para no perder consistencia por ids ya inexistentes que queden volando por ahí
            @persistible_attrs = [{name: :id, type: String, multiple: false, default: description[:default], blank: description[:no_blank], from: description[:from], to: description[:to], validate: description[:validate]}] # la metadata de cada columna de la tabla
        end
        attr_name = description[:named]
        @persistible_attrs.delete_if { |attr| attr[:name] == attr_name }
        @persistible_attrs << {name: attr_name, type: type, multiple: is_multiple, default: description[:default], blank: description[:no_blank], from: description[:from], to: description[:to], validate: description[:validate]} # @persistible_attrs sería como la metadata de la @table del módulo
        @descendants.each do |descendant|
            if(!descendant.instance_methods(false).include? attr_name)
                descendant.send :ORM_add_persistible_attr, type, description, is_multiple: is_multiple # TODO abstraer
            end
        end
        attr_accessor attr_name # define getters+setters para los objetos
    end

    def has_one type, description
        #extend ORM::PersistibleModule
        ORM_add_persistible_attr type, description, is_multiple: false
    end

    def has_many type, description
        #extend ORM::PersistibleModule
        ORM_add_persistible_attr type, description, is_multiple: true
    end

    private :ORM_add_persistible_attr
end


module ORM # a las cosas de acá se puede acceder a través de ORM::<algo>; la idea es no contaminar el namespace

    module PersistibleObject # esto es sólo para objetos; lo estático está en PersistibleModule
        def initialize (*args)
            #puts args
            ((self.class.ORM_get_persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                if (send attr[:name]) == nil
                    send (attr[:name].to_s + '=').to_sym, [] # esto es sólo para inicializar las listas persistibles
                end
            end
            (self.class.ORM_get_persistible_attrs).each do |attr|
                if(attr[:name].to_s != 'id' and attr[:default])
                    send (attr[:name].to_s + '=').to_sym, attr[:default]
                end
            end
            super *args
        end

        def save!
            if @id
               self.class.send :ORM_delete_entry, @id # TODO no estoy seguro de si esta línea es necesaria
               self.class.send :ORM_delete_from_attr_tables, @id
            else
                define_singleton_method(:id) { @id } # TODO el getter se lo damos en la singleton sólo a los que están persistidos; consultar si está bien
                self.class.send :create_method_find_by, "id"
            end
            self_hashed = {} # TODO seguramente haya alguna forma de hacer esto más bonito pero anda
            self.validate!
            ((self.class.ORM_get_persistible_attrs).reject { |attr| attr[:multiple] or ((send attr[:name]) == nil)}).each do |attr|
                attr_value = send attr[:name]
                if attr[:type].ancestors.include? PersistibleObject #is_a? PersistibleModule # TODO abstraer?
                    self_hashed[attr[:name]] = attr_value.save! # se necesita salvar las composiciones simples primero para obtener el id que se guarda acá
                else
                    self_hashed[attr[:name]] = attr_value
                end
            end
            @id = self.class.send :ORM_insert, self_hashed # se guarda el id ahora porque para las composiciones múltiples se necesita tenerlo
            ((self.class.ORM_get_persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                pair_hashed = {} # lo que se guardan son un par de ids que describen la relación de composición
                pair_hashed[('id_' + self.class.name).to_sym] = @id
                (send attr[:name]).each do |elem|
                    if attr[:type].ancestors.include? PersistibleObject #.is_a? PersistibleModule # TODO abstraer?
                        pair_hashed[('id_' + attr[:name].to_s).to_sym] = elem.save!
                    else
                        pair_hashed[attr[:name]] = elem
                    end
                    (self.class.send :ORM_attr_table, attr[:name]).insert pair_hashed
                end
            end

            create_find_by
            return @id # es importante retornar el id para poder hacer save! con composición
        end

        def create_find_by
            self.class.instance_methods(false).reject{|method| method.to_s.end_with?("=") || method((method.to_sym)).arity > 0}.each do |method|
                self.class.send :create_method_find_by, method.to_s
            end
        end

        def refresh!
            exception_if_no_id
            entry = self.class.send :ORM_get_entry, @id
            ((self.class.ORM_get_persistible_attrs).reject { |attr| attr[:multiple] or attr[:name] == :id}).each do |attr| # TODO abstraer
                if attr[:type].ancestors.include? PersistibleObject #.is_a? PersistibleModule
                    attr_final_value = (attr[:type].find_by_id entry[attr[:name]])[0]
                else
                    attr_final_value = entry[attr[:name]]
                end
                if attr[:default] and attr_final_value == nil
                    attr_final_value = attr[:default]
                end
                send (attr[:name].to_s + '=').to_sym, attr_final_value # seteo cada atributo con el valor dado por la entry de la tabla
            end
            ((self.class.ORM_get_persistible_attrs).select { |attr| attr[:multiple] }).each do |attr|
                matching_entries = ((self.class.send :ORM_attr_table, attr[:name]).entries.select { |entry| entry[('id_' + self.class.name).to_sym] == @id })
                elem_enum = matching_entries.map do |entry|
                    if attr[:type].ancestors.include? PersistibleObject #.is_a? PersistibleModule # TODO abstraer?
                        (attr[:type].find_by_id entry[('id_' + attr[:name].to_s).to_sym])[0]
                    else
                        entry[attr[:name]]
                    end
                end
                send (attr[:name].to_s + '=').to_sym, elem_enum.to_a
            end
            self # es necesario retornar self por cómo está implementado instantiate
        end

        def forget! # se asume que no cascadea
            exception_if_no_id
            self.class.send :ORM_notify_deletion, @id
            self.class.send :ORM_delete_entry, @id
            self.class.send :ORM_delete_from_attr_tables, @id
            singleton_class.remove_method :id
            @id = nil # si no se hace esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! puede romper
        end

        def validate!
            ((self.class.ORM_get_persistible_attrs).reject { |attr| attr[:multiple] or attr[:name] == :id}).each do |attr|
                attr_value = send attr[:name]
                other_validations(attr, attr_value)
                exception_if_invalid_values(!(attr_value == nil or attr_value.is_a? attr[:type]))
            end

            ((self.class.ORM_get_persistible_attrs).select { |attr| attr[:multiple]}).each do |attr|
                attr_value = send attr[:name]
                #TODO ver condiciones con has_many
                attr_value.each do |elem|
                    #TODO ver si deberia funciona con elementos no persistibles
                    other_validations(attr, elem)
                    if elem.is_a? PersistibleObject
                        elem.validate!
                    end
                end
            end
        end

        private

        def other_validations (attr, value)
            if attr[:blank]
                validate_blank(value)
            end
            if value.is_a? Numeric
                if attr[:from]
                    validate_from(attr[:from], value)
                end
                if attr[:to]
                    validate_to(attr[:to], value)
                end
            end
            if attr[:validate]
                validate_block(value, &attr[:validate])
            end
        end

        def validate_blank(value)
            if value.nil? || value.empty? then raise 'The instance can not be nil nor empty'
            end
        end

        def validate_from(min, value)
            if value < min then raise 'The instance can not be smaller than the minimum required'
            end
        end

        def validate_to(max, value)
            if value > max then raise 'The instance can not be bigger than the maximum required'
            end
        end

        def validate_block(value, &block)
            if not value.instance_eval(&block) then raise 'The instance has invalid values'
            end
        end

        def exception_if_invalid_values(condition)
            if condition then raise 'The instance has invalid values'
            end
        end

        def exception_if_no_id
            if not @id then raise 'this instance is not persisted' end # TODO armar excepciones decentes
        end
    end


    module PersistibleModule # define exclusivamente lo estático; es necesaria la distinción por la diferencia entre prepend y extend



        def included includer_module
            ORM_add_descendant includer_module
        end

        # TODO armar un module a modo de namespace para los métodos ORM_*?
        def ORM_add_descendant descendant
            # return if (descendant.singleton_class.ancestors & [PersistibleModule, PersistibleClass]).empty?
            @descendants << descendant
            @persistible_attrs.each do |attr|
                descendant.send :ORM_add_persistible_attr, attr[:type], (ORM_get_description attr), is_multiple: attr[:multiple]
            end
        end

        def ORM_get_persistible_attrs
            @persistible_attrs
        end

        def ORM_get_description attr # TODO private
            description_hashed = {}
            description_hashed[:named] = attr[:name]
            description_hashed # TODO todos los demás datos de la descripción
        end

        def ORM_get_all_deletion_observers
            @descendants + @deletion_observers # TODO sacar duplicados? creo que da igual
        end

        def ORM_notify_deletion id # para notificar a las clases (observers) que se borró un id; para mantener consistencia
            self.ORM_get_all_deletion_observers.each do |observer|
                observer.send :ORM_wipe_references_to, self, id
            end
        end

        def ORM_add_deletion_observer a_class # suscripción de una clase a las notificaciones de borrado
            @deletion_observers << a_class
        end

        def all_instances
            @descendants.flat_map(&:all_instances)
        end

        def create_method_find_by name
            selector = ("find_by_#{name}" ).to_sym
            self.define_singleton_method (selector) { |param| all_instances.select { |elem| (elem.send (name.to_sym)) == param } }
        end

        # TODO mover esto a *Class
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

        private :instantiate, :ORM_notify_deletion, :ORM_add_deletion_observer, :ORM_add_descendant, :ORM_get_description, :ORM_get_all_deletion_observers
    end


    module PersistibleClass
        include PersistibleModule

        def inherited descendant_class
            ORM_add_descendant descendant_class
        end

        def ORM_insert hashed_instance 
            @table.insert(hashed_instance)
        end      

        def ORM_get_entry id
            @table.entries.detect { |entry| entry[:id] == id }
        end

        def ORM_delete_entry id
            @table.delete id
        end

        def ORM_wipe_references_to type, id # acá se recibe todo id que haya sido borrado de la tabla de su clase, cuya clase forme parte de una composición con esta clase receptora
            (@persistible_attrs.select { |attr| attr[:type] == type }).each do |attr|
                puts attr[:name].to_s
                if attr[:multiple] # si es composición multiple se borran las entries correspondientes en la tabla de la relación entre las dos clases
                   ((ORM_attr_table attr[:name]).entries.select { |entry| entry[('id_' + attr[:name].to_s).to_sym] == id }).each do |entry|
                        (ORM_attr_table attr[:name]).delete entry[:id]
                    end
                else # si es composición simple, se debe traer el objeto a memoria, setear el atributo en nil, y darle save! de nuevo
                    puts "else"
                    intances_to_update = send ('find_by_' + attr[:name].to_s).to_sym, id
                    intances_to_update.each do |instance|
                        instance.send (attr[:name].to_s + '=').to_sym, nil
                        instance.save!
                    end
                end
            end
        end

        def ORM_attr_table attr_name_symbol # getter de la tabla correspondiente a una relación por has_many
            TADB::DB.table(name + '__' + attr_name_symbol.to_s)
        end

        def all_instances
            super + (instantiate @table.entries)
        end

        def ORM_delete_from_attr_tables id
           (@persistible_attrs.select { |attr| attr[:multiple] }).each do |attr|
               ((ORM_attr_table attr[:name]).entries.select { |entry| entry[('id_' + name).to_sym] == id }).each do |entry|
                    (ORM_attr_table attr[:name]).delete entry[:id]
                end
           end
        end

        private :ORM_insert, :ORM_get_entry, :ORM_delete_entry, :ORM_wipe_references_to, :ORM_attr_table, :ORM_delete_from_attr_tables
    end
end

class Boolean
    def self.new(bool)
        bool
    end

    def self.true
        true
    end

    def self.false
        false
    end
end

class FalseClass
    def is_a?(other)
        other == Boolean || super
    end

    def self.===(other)
        other == Boolean || super
    end
end

class TrueClass
    def is_a?(other)
        other == Boolean || super
    end

    def self.===(other)
        other == Boolean || super
    end
end

# para testear a manopla
=begin
module CosasTesting
    class DNI
        has_one Numeric, named: :number
    end

    class Grade
        has_one Numeric, named: :value
    end

    module Person
        has_one String, named: :full_name
    end

    class Student
        include Person
        has_many Grade, named: :grades
        has_one DNI, named: :dni
    end

    class Ayu < Student
        def initialize
            g = Grade.new
            g.value = 5
            @grades=[g]
            super
        end
    end

    module Person
        has_one Numeric, named: :dni
    end
end
=end
