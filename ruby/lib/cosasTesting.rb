


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

