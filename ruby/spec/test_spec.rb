class Person
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
  has_one Boolean, named: :admin

  attr_accessor :some_other_non_persistible_attribute
end

class Grade
  has_one String, named: :value    # Hasta acá :value es un String
  has_one Numeric, named: :value   # Pero ahora es Numeric
end



describe "Persistencia de objetos sencillos" do
  let(:persona) { Person.new }

  describe 'has_one' do
    it 'un atributo de un objeto persistible puede cambiar el valor multiples veces' do
      persona.first_name = "raul"
      persona.first_name = "jorge"
      expect(persona.first_name).to eq "jorge"
    end

    it 'si defino dos atributos con el mismo nombre, el segundo pisa el primero' do
      Person.has_one Boolean, named: :address
      Person.has_one String, named: :address
      persona.address = "Av. San Martin 2567"
      expect(persona.address.class).to be String
    end

    it 'un objeto no persistible no entiende los mensajes de los objetos persisitibles' do
      object = Object.new
      expect{object.save!}.to raise_error NoMethodError
    end
  end

  describe 'save!' do
    it 'al guardar un objeto persistible adquiere un atributo persistible @id' do
      persona.first_name = "raul"
      persona.last_name = "porcheto"
      persona.save!
      expect(persona.id).not_to be nil
    end

    it 'un objeto persistible sin guardar no tiene un @id' do
      persona.first_name = "raul"
      persona.last_name = "porcheto"
      expect{persona.id}.to raise_error NoMethodError
    end

    it 'un objeto persistible sin datos puede ser guardado' do
      carlos = Person.new
      carlos.save!
      expect(carlos.id).not_to be nil
    end

    it 'al guardar un objeto persistible que ya habia sido borrado adquiere un atributo persistible @id' do
      persona.first_name = "raul"
      persona.last_name = "porcheto"
      persona.save!
      persona.forget!
      persona.save!
      expect(persona.id).not_to be nil
    end
  end

  describe 'refresh!' do
    it 'al refrescar un objeto al que se le cambio el valor del atributo, su valor vuelve al guardado' do #TODO ver nombre por otro mas lindo gg
      persona.first_name = "jose"
      persona.save!
      persona.first_name = "pepe"
      persona.refresh!
      expect(persona.first_name).to eq "jose"
    end

    it 'no se puede refrescar un objeto sin id' do
      objeto = Person.new
      expect{objeto.refresh!}.to raise_error 'this instance is not persisted' #TODO ver de cambiar cuando se hagan excepciones decentes (?)
    end
  end

  describe 'forget!' do
    it 'un objeto al que se le mando forget! deja de tener @id' do
      persona.first_name = "arturo"
      persona.last_name = "puig"
      persona.save!
      persona.forget!
      expect{persona.refresh!}.to raise_error 'this instance is not persisted' #TODO ver de cambiar cuando se hagan excepciones decentes (?)
    end
  end

  describe 'all_instances' do
    class Golondrina
      has_one String, named: :nombre
    end
    class Pajaro
      has_one String, named: :nombre
    end

    it 'una clase sin objetos pesistidos devuelve un array vacio' do
      TADB::DB.clear_all()
      expect(Golondrina.all_instances).to eq []
    end

    it 'una clase con un objeto persistido y uno no persistido devuelve ese objeto' do
      TADB::DB.clear_all()
      pepita = Golondrina.new
      pepita.nombre = "pepita"
      pepita.save!
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      expect(Golondrina.all_instances.first.id).to eq pepita.id
    end

    it 'al borrar un objeto persistido, este deja de pertenecer a la lista de instacias persistidas' do
      TADB::DB.clear_all()
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      jorge.save!
      jorge.forget!
      expect(Golondrina.all_instances).to eq []
    end

    it 'un objeto persistidos que fue borrado y guardado de nuevo pertenece a la lista de instacias persistidas' do
      TADB::DB.clear_all()
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      jorge.save!
      jorge.forget!
      jorge.save!
      expect(Golondrina.all_instances.first.id).to eq jorge.id
    end

    it 'una clase con 2 objetos persistidos y un objeto persistido borrado tiene dos instancias pesistidas' do
      TADB::DB.clear_all()
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      jorge.save!
      jorge.forget!
      pepita = Golondrina.new
      pepita.nombre = "pepita"
      pepita.save!
      paulina = Golondrina.new
      paulina.nombre = "paulina"
      paulina.save!
      expect(Golondrina.all_instances.size).to eq 2
    end
  end

  describe 'find_by_<what>' do
    class Student
      has_one String, named: :full_name
      has_one Numeric, named: :grade

      def promoted
        self.grade > 8
      end

      def has_last_name(last_name)
        self.full_name.split(' ')[1] === last_name
      end

    end

    it 'No se puede buscar un objeto con un metodo especifico que recibe argumentos' do
      TADB::DB.clear_all()
      nahuel = Student.new
      nahuel.full_name = "Nahuel Rodriguez"
      nahuel.save!
      expect{Student.find_by_has_last_name ("Rodriguez")}.to raise_error NoMethodError
    end

    it 'Se puede buscar un objeto con un metodo especifico' do
      TADB::DB.clear_all()
      nahuel = Student.new
      nahuel.full_name = "Nahuel Rodriguez"
      nahuel.save!
      expect((Student.find_by_full_name("Nahuel Rodriguez")).first.id).to eq (nahuel.id)
    end

    it 'Se puede buscar varios objetos con un metodo especifico' do
      TADB::DB.clear_all()
      nahuel = Student.new
      nahuel.grade = 7
      nahuel.save!
      dani = Student.new
      dani.grade = 7
      dani.save!
      mica = Student.new
      mica.grade = 8
      mica.save!
      expect((Student.find_by_grade (7)).size).to eq 2
    end

    it 'No se puede buscar por un metodo que no existe' do
      TADB::DB.clear_all()
      nahuel = Student.new
      expect{Student.find_by_address "calle falsa 123"}.to raise_error NoMethodError
    end

  end
end