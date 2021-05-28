class Person
  has_one String, named: :first_name
  has_one String, named: :last_name

  attr_accessor :some_other_non_persistible_attribute

  def initialize (first_name = nil, last_name = nil)
    @first_name = first_name
    @last_name = last_name
  end
end

class Grade
  has_one Numeric, named: :value
  def initialize (value = nil)
    @value = value
  end
end

describe "Persistencia de objetos" do

  after do
    TADB::DB.clear_all
  end

  describe 'has_one' do
    it 'un atributo de un objeto persistible puede cambiar el valor multiples veces' do
      persona = Person.new("raul", "Gomes")
      persona.first_name = "jorge"
      expect(persona.first_name).to eq "jorge"
    end

    it 'La ultima definicion de un atributo pisa las anteriores' do
      Empty = Class.new()

      Empty.has_one Boolean, named: :address
      Empty.has_one String, named: :address

      object = Empty.new
      object.address = "Av. San Martin 2567"
      expect(object.address.class).to be String
    end

    it 'un objeto no persistible no entiende los mensajes de los objetos persisitibles' do
      object = Object.new
      expect{object.save!}.to raise_error NoMethodError
    end
  end

  describe 'save!' do
    it 'al guardar un objeto persistible adquiere un atributo persistible @id' do
      persona = Person.new("raul", "porcheto")
      persona.save!
      expect(persona.id).not_to be nil
    end

    it 'un objeto persistible sin guardar no tiene un @id' do
      persona = Person.new("raul", "porcheto")
      expect(persona.id).to eq nil
    end

    it 'Un objeto persistible puede volver a guardarse despues de haber sido eliminado' do
      persona = Person.new("raul", "porcheto")
      persona.save!
      persona.forget!
      persona.save!
      expect(persona.id).not_to be nil
    end
  end

  describe 'refresh!' do
    it 'Al refrescar un objeto persistible sus atributos toman los valores guardados' do
      persona = Person.new("raul", "porcheto")
      persona.save!
      persona.first_name = "pepe"
      persona.refresh!
      expect(persona.first_name).to eq "raul"
    end

    it 'No se puede refrescar un objeto que no fue guardado' do
      persona = Person.new("raul", "porcheto")
      expect{persona.refresh!}.to raise_error 'this instance is not persisted'
    end
  end

  describe 'forget!' do
    it 'Al eliminar un objeto persistible este deja de tener @id' do
      persona = Person.new("raul", "porcheto")
      persona.save!
      persona.forget!
      expect{persona.refresh!}.to raise_error 'this instance is not persisted'
    end
  end

  describe 'all_instances' do


    class Pajaro
      has_one String, named: :nombre

      def initialize nombre = nil
        @nombre = nombre
      end
    end

    class Benteveo < Pajaro

    end

    it 'Si una clase recibe all intances devuelve tambien las instancias de sus decencientes' do
      pepito = Benteveo.new("pepito")
      pepito2 = Pajaro.new("pepito2")
      pepito.save!
      pepito2.save!
      expect(Pajaro.all_instances.map{|elem| elem.id}).to eq([pepito.id, pepito2.id])
    end

    it 'una clase sin objetos pesistidos no devuelve instancias' do
      pepito = Pajaro.new("pepito")
      expect(Pajaro.all_instances).to eq []
    end

    it 'Los objetos persistidos borrados dejan de ser instacias persistidas' do
      jorge = Pajaro.new("jorge")
      jorge.save!
      jorge.forget!
      expect(Pajaro.all_instances).to eq []
    end

    it 'Los objetos persistidos borrados pueden volver a ser instacias persistidas' do
      jorge = Pajaro.new("jorge")
      jorge.save!
      jorge.forget!
      jorge.save!
      expect(Pajaro.all_instances.first.id).to eq jorge.id
    end

    it 'Una clase solo devuelve sus instancias persistidas' do
      jorge = Pajaro.new("jorge")
      jorge.save!
      jorge.forget!
      pepita = Pajaro.new("pepita")
      pepita.save!
      paulina = Pajaro.new("paulina")
      paulina.save!
      expect(Pajaro.all_instances.size).to eq 2
    end
  end

  describe 'find_by_<what>' do
    class Student
      has_one String, named: :full_name
      has_one Numeric, named: :grade

      def initialize (full_name = nil, grade = 0)
        @full_name = full_name
        @grade = grade
      end

      def has_last_name(last_name)
        self.full_name.split(' ')[1] === last_name
      end

      def promoted
        self.grade > 8
      end

    end


    it 'No se puede buscar un objeto con un metodo especifico que recibe argumentos' do
      nahuel = Student.new("Nahuel Rodriguez", 5)
      nahuel.save!
      expect{Student.find_by_has_last_name("Rodriguez")}.to raise_error NoMethodError
    end

    it 'No se puede buscar un objeto con un metodo setter' do
      nahuel = Student.new("Nahuel Rodriguez", 5)
      nahuel.save!
      expect{Student.find_by_grade=(6)}.to raise_error NoMethodError
    end

    it 'Se puede buscar un objeto con un método que no sea un getter' do
      nahuel = Student.new("Nahuel Rodriguez", 9)
      nahuel.save!
      expect((Student.find_by_promoted(true)).first.id).to eq (nahuel.id)
    end

    it 'Se puede buscar un objeto con un metodo especifico' do
      nahuel = Student.new("Nahuel Rodriguez", 5)
      nahuel.save!
      expect((Student.find_by_full_name("Nahuel Rodriguez")).first.id).to eq (nahuel.id)
    end

    it 'Se puede buscar varios objetos con un metodo especifico' do
      nahuel = Student.new("Nahuel Rodriguez", 7)
      nahuel.save!
      dani = Student.new("Dani Perez", 7)
      dani.save!
      mica = Student.new("Mica Gonzales", 8)
      mica.save!
      expect((Student.find_by_grade (7)).size).to eq 2
    end

    it 'No se puede buscar por un metodo que no existe' do
      expect{Student.find_by_address "calle falsa 123"}.to raise_error NoMethodError
    end

  end

  describe 'Composicion con un unico objeto' do

    class Nota
      has_one Numeric, named: :valor

      def initialize (valor = nil)
        @valor = valor
      end
    end

    class Estudiante
      has_one String, named: :nombre
      has_one Nota, named: :nota
      def initialize (nombre = nil, nota = nil)
        @nombre = nombre
        @nota = nota
      end
    end

    it 'El atributo compuesto devuelve el objeto' do
      nota = Nota.new(8)
      leo = Estudiante.new("leo sbaraglia", nota)
      leo.save!
      expect(leo.nota.valor).to eq 8
    end

    it 'El atributo compuesto refrescado tiene el valor guardado' do
      nota = Nota.new(8)
      juan = Estudiante.new("juan sbaraglia", nota)
      juan.save!
      juan.nota = Nota.new(9)
      juan.refresh!
      expect(juan.nota.valor).to eq 8
    end

    it 'El atributo compuesto se puede borrar y volver a guardar' do
      juan = Estudiante.new("juan sbaraglia", Nota.new(8))
      juan.save!
      juan.forget!
      juan.nota = Nota.new(9)
      juan.save!
      juan.nota = Nota.new(10)
      juan.refresh!
      expect(juan.nota.valor).to eq 9
    end

    it 'El atributo compuesto puede ser actualizado desde afuera del objeto' do
      nota = Nota.new(8)
      jose = Estudiante.new("jose sbaraglia", nota)
      jose.save!
      jose.nota = Nota.new(9)
      nota.valor = 2
      nota.save!
      jose.refresh!
      expect(jose.nota.valor).to eq 2
    end

    it 'El atributo compuesto puede ser actualizado desde otro objeto' do
      juani = Estudiante.new("juani sbaraglia", Nota.new(9))
      juani.save!
      pepito = Estudiante.new("Pepito Maldonado", juani.nota)
      pepito.nota.valor = 10
      pepito.save!
      juani.refresh!
      expect(juani.nota.valor).to eq 10
    end


    it 'El atributo compuesto tiene la misma referencia que otro atributo compuesto con el mismo objeto' do
      nota = Nota.new(8)
      jose = Estudiante.new("jose sbaraglia", nota)
      jose.save!
      paula = Estudiante.new("Paula Sbaraglia", nota)
      paula.nota.valor = 4
      paula.save!
      jose.refresh!
      expect(jose.nota.valor).to eq 4
    end

    it 'Un objeto compuesto con un objeto no tiene la referencia a este cuando se borra' do
      nota = Nota.new(8)
      leo = Estudiante.new("leo sbaraglia", nota)
      leo.save!
      nota.forget!
      leo.refresh!
      expect(leo.nota).to eq nil
    end
  end

  describe 'Composicion con multiples objetos' do
    class Alumno
      has_one String, named: :nombre
      has_many Nota, named: :notas

      def initialize (nombre = nil, notas = [])
        @nombre = nombre
        @notas = notas
      end

    end

    it 'En objeto compuesto la lista de un has_many se inicializa vacia' do
      class EstudianteEspecial
        has_many Nota, named: :notas
      end
      tomas = EstudianteEspecial.new()
      expect(tomas.notas).to eq []
    end


    it 'Composicion con has_many' do
      unaNota = Nota.new(8)
      otraNota = Nota.new(5)
      guido = Alumno.new("Guido Bevilacqua", [unaNota, otraNota])
      guido.save!
      expect(guido.notas).to eq [unaNota, otraNota]
    end

    it 'Un objeto compuesto con has_many se puede refrescar' do
      unaNota = Nota.new(8)
      otraNota = Nota.new(5)
      guido = Alumno.new("Guido Bevilacqua", [unaNota, otraNota])
      guido.save!
      guido.notas.push(Nota.new(9))
      guido.refresh!
      expect(guido.notas.map{|x| x.id}).to eq [unaNota.id, otraNota.id]
    end


    it 'Un objeto compuesto con has_many borra las referencias a los objetos borrados' do
      unaNota = Nota.new(8)
      otraNota = Nota.new(5)
      guido = Alumno.new("Guido Bevilacqua", [unaNota, otraNota])
      guido.save!
      unaNota.forget!
      otraNota.forget!
      guido.refresh!
      expect(guido.notas.empty?).to eq true
    end

  end

  describe "Herencia" do

    module Legajo
      has_one Numeric, named: :legajo
    end

    module Address
      has_one String, named: :street
      has_one Numeric, named: :number
    end

    class Human
      include Legajo
      has_one String, named: :first_name
      has_one String, named: :last_name

      attr_accessor :some_other_non_persistible_attribute
    end

    class Employee < Human
      include Address
      has_one String, named: :role
      has_one Boolean, named: :has_children

    end

    module Phone
      has_one Numeric, named: :number

    end

    class Manager
      include Phone
      has_one String, named: :next_meeting

    end

    class Assistant
      include Phone
      has_one String, named: :name

    end


    let(:juan){Human.new}
    let(:juan_boss){Employee.new}

    it 'se deberia persistir la clase que incluye un module persistible' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_children = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(juan.id).not_to eq(nil)
    end

    it 'se deberia persistir una herencia' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_children = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(Employee.all_instances).not_to eq([])
    end

    it 'find_by en superclase debe traer elementos de subclases' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_children = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(Human.all_instances.size).to eq(2)
    end

    it 'find_by en modulos incluidos en varias clases debe traer solo los elementos de la clase solicitada' do
      m = Manager.new
      m.number = 123
      m.next_meeting = "Monday"
      m.save!

      expect(Manager.all_instances.size).to eq(1)
    end
  end

  describe 'validate!' do

    it 'No se puede guardar un objeto persistente con un valor de tipo diferente al declarado para un objeto con atributos simples' do
      juan = Student.new(5)
      expect{juan.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto persistente si los tipos coinciden' do
      cande = Estudiante.new("Cande Sierra",  Nota.new(10))
      cande.save!
      expect(cande.id).not_to eq nil
    end

    it 'No se puede guardar un objeto persistente con composición si los tipos no coinciden' do
      tom = Estudiante.new("Thomas Marlow", Nota.new("Diez"))
      expect{tom.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto persistente con atributos complejos si los tipos coinciden' do
      ara = Alumno.new("Ara", [Nota.new(8), Nota.new(5)])
      ara.save!
      expect(ara.id).not_to eq nil
    end

  end

  describe 'Validacion no_blank' do
    class Bird
      has_one String, named: :name, no_blank: true

      def initialize (name = nil)
        @name = name
      end
    end

    class Birds
      has_many String, named: :names, no_blank: true

      def initialize (names = [])
        @names = names
      end
    end

    it 'No se puede guardar un objeto si tiene un atirbuto vacío' do
      juancito = Bird.new("")
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'No se puede guardar un objeto si tiene un atirbuto nulo' do
      juancito = Bird.new
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'Se puede guardar un objeto si no tiene un atirbuto nulo' do
      juancito = Bird.new("Juancito De Las Nieves")
      juancito.save!
      expect(juancito.id).not_to eq nil
    end

    it 'No se puede guardar una coleccion que tiene objetos vacíos' do
      juancito = Birds.new(["Juan", ""])
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'No se puede guardar una coleccion que tiene nil' do
      juancito = Birds.new(["Juan", nil])
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'Se puede guardar una coleccion sin objetos vacios o nil' do
      juancito = Birds.new(["Juan", "Jorge"])
      juancito.save!
      expect(juancito.id).not_to eq nil
    end
  end

  describe 'Validacion from' do
    class Cat
      has_one Numeric, named: :age, from: 5, to: 20

      def initialize (age)
        @age = age
      end
    end

    class Dog
      has_many Numeric, named: :numerosFavoritos, from:0, to:100

      def initialize (numerosFavoritos = [])
        @numerosFavoritos = numerosFavoritos
      end
    end

    it 'Has many - No se puede guardar un obejeto si tiene algun valor menor al minimo requerido' do
      tiff = Dog.new([5, -2])
      expect{tiff.save!}.to raise_error 'The instance can not be smaller than the minimum required'
    end

    it 'Has many - No se puede guardar un obejeto si tiene algun valor mayor al maximo requerido' do
      tiff = Dog.new([5, 200])
      expect{tiff.save!}.to raise_error 'The instance can not be bigger than the maximum required'
    end

    it 'Has many - Se puede guardar un objeto si tiene sus valores dentro del rango requerido' do
      tiff = Dog.new([5,99])
      tiff.save!
      expect(tiff.id).not_to eq nil
    end

    it 'No se puede guardar un objeto si tiene un valor menor al minimo requerido' do
      nala = Cat.new(2)
      expect{nala.save!}.to raise_error 'The instance can not be smaller than the minimum required'
    end

    it 'Se puede guardar un objeto si tiene un valor dentro del rango requerido' do
      alekai = Cat.new(6)
      alekai.save!
      expect(alekai.id).not_to eq nil
    end

    it 'No se puede guardar un objeto si tiene un valor mayor al maximo requerido' do
      olivia = Cat.new(50)
      expect{olivia.save!}.to raise_error 'The instance can not be bigger than the maximum required'
    end
  end

  describe 'Validacion por bloque' do

    class Toy
      has_one String, named: :name

      def initialize (name = nil)
        @name = name
      end
    end

    class Tiger
      has_many Toy, named: :toys, validate: proc{name.length > 4}

      def initialize (toys = [])
        @toys = toys
      end
    end

    it 'Se puede guardar un objeto con composicion simple si cumple con la condición del bloque' do
      mora = Tiger.new([Toy.new("Voleyball ball")])
      mora.save!
      expect(mora.id).not_to eq nil
    end

    it 'No se puede guardar un objeto con composicion simple si no cumple con la condición del bloque' do
      mora = Tiger.new([Toy.new("ball")])
      expect {mora.save!}.to raise_error 'The instance has invalid values'
    end

    it 'No se puede guardar un objeto si no cumple con la condición del bloque' do
      mora = Tiger.new([Toy.new("Voleyball ball"), Toy.new("ball")])
      expect {mora.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto compuesto si cumple con la condición del bloque' do
      mora = Tiger.new([Toy.new("Voleyball ball"), Toy.new("balls")])
      mora.save!
      expect(mora.id).not_to eq nil
    end
  end

  describe 'Valores por defecto'  do
    class Room
      has_one String, named: :teacher, default: 'Lisa'
    end

    it 'Cuando inicializa la instancia le asigna el valor por defecto' do
      room = Room.new
      expect(room.teacher).to eq 'Lisa'
    end

    it 'si se le asigna un valor distinto al default debe respetarlo' do
      room = Room.new
      room.teacher = 'Bart'
      expect(room.teacher).to eq 'Bart'
    end

    it 'Si se guarda nil y se resfreca debe setear el default' do
      room = Room.new
      room.teacher = nil
      room.save!
      room.refresh!
      expect(room.teacher).to eq 'Lisa'
    end

  end


end

class A
  has_one String, named: :pepito
end

class A
  def hola()
    pepito == "hola"
  end
end