require 'tadb'

class Module

    def has_one type, description
        extend ORM::PersistibleModule
        ORM_add_persistible_attr type, description, is_multiple: false
    end

    def has_many type, description
        extend ORM::PersistibleModule
        ORM_add_persistible_attr type, description, is_multiple: true
    end

end


module ORM # a las cosas de acá se puede acceder a través de ORM::<algo>; la idea es no contaminar el namespace

    class ORM_Error < StandardError
        def initialize(msg="Error")
            super(msg)
        end
    end

    class Validation_no_blank
        def initialize needs_validation
            @needs_validation = needs_validation
        end

        def validate(value)
            if @needs_validation and (value.nil? || value.empty?) then raise ORM_Error.new("The instance can not be nil nor empty")
            end
        end
    end

    class Validation_by_block
        def initialize block
            @block = block
        end
        def validate value
            unless value.instance_eval(&@block) then raise ORM_Error.new('The instance has invalid values')
            end
        end
    end

    class Validation_to
        def initialize max
            @max = max
        end
        def validate value
            if value > @max then raise ORM_Error.new('The instance can not be bigger than the maximum required')
            end
        end
    end

    class Validation_from
        def initialize min
            @min = min
        end
        def validate value
            if value < @min then raise ORM_Error.new('The instance can not be smaller than the minimum required')
            end
        end
    end

    module PersistibleObject # esto es sólo para objetos; lo estático está en PersistibleModule
        attr_reader :id

        def initialize (*args)
            initialize_persistible_lists
            initialize_default_attr
            super *args
        end

        def save!
            self.class.send :ORM_delete_entry, @id
            self.class.send :ORM_delete_from_attr_tables, @id
            self_hashed = {}
            validate!
            (reject_nil_attr get_non_multiple_attr).each do |attr|
                attr_value = send attr[:named]
                if is_persistible_object? attr[:type]
                    self_hashed[attr[:named]] = attr_value.save! # se necesita salvar las composiciones simples primero para obtener el id que se guarda acá
                else
                    self_hashed[attr[:named]] = attr_value
                end
            end
            @id = self.class.send :ORM_insert, self_hashed # se guarda el id ahora porque para las composiciones múltiples se necesita tenerlo
            (get_multiple_attr).each do |attr|
                pair_hashed = {} # lo que se guardan son un par de ids que describen la relación de composición
                pair_hashed[get_id_ self.class.name] = @id
                (send attr[:named]).each do |elem|
                    if is_persistible_object? attr[:type]
                        pair_hashed[get_id_ attr[:named].to_s] = elem.save!
                    else
                        pair_hashed[attr[:named]] = elem
                    end
                    (self.class.send :ORM_attr_table, attr[:named]).insert pair_hashed #inserta a la tabla
                end
            end
            return @id # es importante retornar el id para poder hacer save! con composición
        end

        def refresh!
            validate_id
            entry = self.class.send :ORM_get_entry, @id
            (reject_id(get_non_multiple_attr)).each do |attr|
                if is_persistible_object? attr[:type]
                    attr_final_value = (attr[:type].find_by_id entry[attr[:named]])[0]
                else
                    attr_final_value = entry[attr[:named]]
                end
                send (setter attr), attr_final_value # seteo cada atributo con el valor dado por la entry de la tabla
            end
            get_multiple_attr.each do |attr|
                send (setter attr), (get_attr_values attr).to_a
            end
            self # es necesario retornar self por cómo está implementado instantiate
        end

        def forget! # se asume que no cascadea
            validate_id
            self.class.send :ORM_notify_deletion, @id
            self.class.send :ORM_delete_entry, @id
            self.class.send :ORM_delete_from_attr_tables, @id
            @id = nil # si no se hace esto, el id viejo queda volando adentro del objeto y al hacer un nuevo save! puede romper
        end

        def validate!
            reject_id(get_non_multiple_attr).each do |attr|
                attr_value = send attr[:named]
                attr[:validations].each do |validation|
                    validation.validate attr_value
                end
                if attr[:default] and attr_value == nil
                    attr_value = attr[:default]
                    send (setter attr), attr_value
                end
                validate_values_by((attr_value.is_a? attr[:type] or attr_value == nil))
            end
            get_multiple_attr.each do |attr|
                attr_value = send attr[:named]
                attr_value.each do |elem|
                    attr[:validations].each do |validation|
                        validation.validate elem
                    end
                    elem.validate! if elem.is_a? PersistibleObject
                end
            end
        end

        private

        def get_attr_values attr
            (get_matching_entries attr).map do |entry|
                if is_persistible_object? attr[:type]
                    (attr[:type].find_by_id entry[get_id_ attr[:named].to_s])[0]
                else
                    entry[attr[:named]]
                end
            end
        end

        def get_matching_entries attr
            (self.class.send :ORM_attr_table, attr[:named]).entries.select { |entry| entry[get_id_ self.class.name] == @id }
        end

        def get_id_ name
            ('id_' + name).to_sym
        end

        def initialize_persistible_lists
            get_multiple_attr.each do |attr|
                if (send attr[:named]) == nil
                    send (setter attr), [] # esto es sólo para inicializar las listas persistibles
                end
            end
        end

        def initialize_default_attr
            (self.class.ORM_get_persistible_attrs).each do |attr|
                if(attr[:named].to_s != 'id' and attr[:default])
                    send (setter attr), attr[:default]
                end
            end
        end

        def setter attr
            (attr[:named].to_s + '=').to_sym
        end #esto es privado?

        def validate_values_by(condition)
            unless condition then raise ORM_Error.new('The instance has invalid values')
            end
        end

        def validate_id
            if not @id then raise ORM_Error.new('this instance is not persisted') end
        end


        def is_persistible_object? type
            type.ancestors.include? PersistibleObject
        end

        def get_non_multiple_attr
            self.class.ORM_get_persistible_attrs.reject{ |attr| attr[:multiple]}
        end

        def get_multiple_attr
            self.class.ORM_get_persistible_attrs.select{ |attr| attr[:multiple]}
        end

        def reject_nil_attr attr_list
            attr_list.reject{|attr| (send attr[:named]) == nil}
        end

        def reject_id attr_list
            attr_list.reject{|attr| attr[:named] == :id}
        end

    end


    module PersistibleModule # define exclusivamente lo estático; es necesaria la distinción por la diferencia entre prepend y extend
        def method_added method_name
            if valid_find_by_method method_name
                create_method_find_by method_name
            end
        end

        def ORM_add_persistible_attr type, description, is_multiple: #TODO poner en otro lado para no mandarlo con send y revisar si tenemos otros asi
            if type.is_a? ORM::PersistibleModule
                type.send :ORM_add_deletion_observer, self
            end
            #TODO tirar excepcion si se intenta crear algo que no sea numeric con from: o to:
            unless @persistible_attrs
                if self.is_a? Class
                    initialize_find_by_methods
                    extend ORM::PersistibleClass
                    prepend ORM::PersistibleObject # para que los objetos tengan el comportamiento de persistencia; es prepend para poder agregarle comportamiento al constructor
                    @table = TADB::DB.table(name)
                end
                @descendants = []
                @deletion_observers = [] # tiene las clases a las que hay que notificar borrados para no perder consistencia por ids ya inexistentes que queden volando por ahí
                @persistible_attrs = [{named: :id, type: String, multiple: false}]
            end
            attr_name = description[:named]
            @persistible_attrs.delete_if { |attr| attr[:named] == attr_name }
            @persistible_attrs << {named: attr_name, type: type, multiple: is_multiple, default: description[:default], validations: (getValidations description)} # @persistible_attrs sería como la metadata de la @table del módulo
            @descendants.each do |descendant|
                unless descendant.instance_methods(false).include? attr_name #evita que superclase pise metodos de subclases
                    descendant.send :ORM_add_persistible_attr, type, description, is_multiple: is_multiple
                end
            end
            attr_accessor attr_name # define getters+setters para los objetos
        end

        def getValidations description
            validations = [
              {class: Validation_no_blank, param: description[:no_blank]},
              {class: Validation_from, param: description[:from]},
              {class: Validation_to, param: description[:to]},
              {class: Validation_by_block, param: description[:validate]}
            ]
            (reject_nil_validations  validations).map do |validation|
                validation[:class].new validation[:param]
            end
        end

        def reject_nil_validations validations
            validations.reject{|validation| validation[:param] == nil}
        end

        def included includer_module
            ORM_add_descendant includer_module
        end

        def valid_find_by_method method_name
            instance_method(method_name).arity == 0
        end

        def initialize_find_by_methods
            create_method_find_by 'id'
            instance_methods(false).select{|method| valid_find_by_method method}.each do |method|
                create_method_find_by method
            end
        end

        def ORM_add_descendant descendant
            # return if (descendant.singleton_class.ancestors & [PersistibleModule, PersistibleClass]).empty?
            @descendants << descendant
            @persistible_attrs.each do |attr|
                descendant.extend PersistibleModule
                descendant.send :ORM_add_persistible_attr, attr[:type], attr, is_multiple: attr[:multiple]
            end
        end

        def ORM_get_persistible_attrs
            @persistible_attrs
        end

        def ORM_get_all_deletion_observers
            @descendants | @deletion_observers
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
            self.define_singleton_method(selector) { |param| all_instances.select { |elem| (elem.send(name.to_sym)) == param } }
        end

        private  :reject_nil_validations, :getValidations, :ORM_notify_deletion, :ORM_add_deletion_observer, :ORM_add_descendant, :ORM_get_all_deletion_observers, :valid_find_by_method, :create_method_find_by, :initialize_find_by_methods
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

        def get_persistible_attr_by_type type
            @persistible_attrs.select { |attr| attr[:type] == type }
        end

        def ORM_wipe_references_to type, id # acá se recibe todoo id que haya sido borrado de la tabla de su clase, cuya clase forme parte de una composición con esta clase receptora
            (get_persistible_attr_by_type type).each do |attr|
                if all_instances.empty?
                    return
                end
                if attr[:multiple] # si es composición multiple se borran las entries correspondientes en la tabla de la relación entre las dos clases
                    (get_entries_referencing_id attr[:named], id ).each do |entry|
                        (ORM_attr_table attr[:named]).delete entry[:id]
                    end
                else # si es composición simple, se debe traer el objeto a memoria, setear el atributo en nil, y darle save! de nuevo
                    intances_to_update = send (get_find_by attr[:named]), id
                    intances_to_update.each do |instance|
                        instance.send (setter attr), nil
                        instance.save!
                    end
                end
            end

        end

        def get_find_by name
            ('find_by_' + name.to_s).to_sym
        end

        def get_entries_referencing_id attr_name , id
            ((ORM_attr_table attr_name).entries.select { |entry| entry[id_getter attr_name.to_s] == id })
        end

        def ORM_attr_table attr_name_symbol # getter de la tabla correspondiente a una relación por has_many
            TADB::DB.table(name + '__' + attr_name_symbol.to_s)
        end

        def all_instances
            super + (instantiate @table.entries)
        end

        def ORM_delete_from_attr_tables id
           (@persistible_attrs.select { |attr| attr[:multiple] }).each do |attr|
               (get_entries_referencing_id attr[:named], id).each do |entry|
                    (ORM_attr_table attr[:named]).delete entry[:id]
                end
           end
        end

        def id_getter name
            ('id_' + name).to_sym
        end

        def instantiate entries # dada una lista de entries, devuelve la lista de instancias correspondientes
            entries.map do |entry|
                instance = new
                instance.instance_eval { @id = entry[:id] }
                instance.refresh!
            end
        end

        private :ORM_add_persistible_attr, :get_persistible_attr_by_type, :instantiate, :ORM_insert, :ORM_get_entry, :ORM_delete_entry, :ORM_wipe_references_to, :ORM_attr_table, :ORM_delete_from_attr_tables
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


=begin

module CosasTestingReloaded
    class Nota
        has_one Numeric, named: :valor

        def initialize (valor = nil)
          @valor = valor
        end
    end

    class Alumno
        has_one String, named: :nombre
        has_many Nota, named: :notas

        def initialize (nombre = nil, notas = [])
          @nombre = nombre
          @notas = notas
        end
    end
end
=end

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
