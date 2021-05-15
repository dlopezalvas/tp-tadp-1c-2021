class Person
  has_one String, named: :first_name
  has_one String, named: :last_name

  attr_accessor :some_other_non_persistible_attribute
end

class Empty
end

class Grade
  has_one String, named: :value    # Hasta acÃ¡ :value es un String
  has_one Numeric, named: :value   # Pero ahora es Numeric
end

describe "Persistencia de objetos sencillos" do #TODO cambiar nombre
  let(:persona) { Person.new }

  after do
    TADB::DB.clear_all
  end

  describe 'has_one' do
    it 'un atributo de un objeto persistible puede cambiar el valor multiples veces' do
      persona.first_name = "raul"
      persona.first_name = "jorge"
      expect(persona.first_name).to eq "jorge"
    end

    it 'si defino dos atributos con el mismo nombre, el segundo pisa el primero' do
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
      expect(carlos.id).not_to eq nil
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
      persona.last_name = "Lopez"
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
      expect(Golondrina.all_instances).to eq []
    end

    it 'una clase con un objeto persistido y uno no persistido devuelve ese objeto' do
      pepita = Golondrina.new
      pepita.nombre = "pepita"
      pepita.save!
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      expect(Golondrina.all_instances.first.id).to eq pepita.id
    end

    it 'al borrar un objeto persistido, este deja de pertenecer a la lista de instacias persistidas' do
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      jorge.save!
      jorge.forget!
      expect(Golondrina.all_instances).to eq []
    end

    it 'un objeto persistidos que fue borrado y guardado de nuevo pertenece a la lista de instacias persistidas' do
      jorge = Golondrina.new
      jorge.nombre = "jorge"
      jorge.save!
      jorge.forget!
      jorge.save!
      expect(Golondrina.all_instances.first.id).to eq jorge.id
    end

    it 'una clase con 2 objetos persistidos y un objeto persistido borrado tiene dos instancias pesistidas' do
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

      def has_last_name(last_name)
        self.full_name.split(' ')[1] === last_name
      end

    end

    it 'No se puede buscar un objeto con un metodo especifico que recibe argumentos' do
      nahuel = Student.new
      nahuel.full_name = "Nahuel Rodriguez"
      nahuel.grade = 5
      nahuel.save!
      expect{Student.find_by_has_last_name ("Rodriguez")}.to raise_error NoMethodError
    end

    it 'Se puede buscar un objeto con un metodo especifico' do
      nahuel = Student.new
      nahuel.full_name = "Nahuel Rodriguez"
      nahuel.grade = 5
      nahuel.save!
      expect((Student.find_by_full_name("Nahuel Rodriguez")).first.id).to eq (nahuel.id)
    end

    it 'Se puede buscar varios objetos con un metodo especifico' do
      nahuel = Student.new
      nahuel.full_name = "Nahuel Rodriguez"
      nahuel.grade = 7
      nahuel.save!
      dani = Student.new
      dani.full_name = "Dani Perez"
      dani.grade = 7
      dani.save!
      mica = Student.new
      mica.full_name = "Mica Gonzales"
      mica.grade = 8
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
    end

    class Estudiante
      has_one String, named: :nombre
      has_one Nota, named: :nota
    end

    it 'El atributo compuesto devuelve el objeto' do
      leo = Estudiante.new
      leo.nombre = "leo sbaraglia"
      leo.nota = Nota.new
      leo.nota.valor = 8
      leo.save!
      expect(leo.nota.valor).to eq 8
    end

    it 'El atributo compuesto refrescado tiene el valor guardado' do
      juan = Estudiante.new
      juan.nombre = "juan sbaraglia"
      juan.nota = Nota.new
      juan.nota.valor = 8
      juan.save!
      juan.nota = Nota.new
      juan.nota.valor = 9
      juan.refresh!
      expect(juan.nota.valor).to eq 8
    end

    it 'El atributo compuesto se puede borrar y volver a guardar' do
      juan = Estudiante.new
      juan.nombre = "juan sbaraglia"
      juan.nota = Nota.new
      juan.nota.valor = 8
      juan.save!
      juan.forget!
      juan.nota = Nota.new
      juan.nota.valor = 9
      juan.save!
      juan.nota = Nota.new
      juan.nota.valor = 10
      juan.refresh!
      expect(juan.nota.valor).to eq 9
    end

    it 'El atributo compuesto puede ser actualizado desde afuera del objeto' do
      jose = Estudiante.new
      jose.nombre = "jose sbaraglia"
      nota = Nota.new
      nota.valor = 8
      jose.nota = nota
      jose.save!
      jose.nota = Nota.new
      jose.nota.valor = 9
      nota.valor = 2
      nota.save!
      jose.refresh!
      expect(jose.nota.valor).to eq 2
    end

    it 'El atributo compuesto puede ser actualizado desde otro objeto' do
      pepito = Estudiante.new
      juani = Estudiante.new
      juani.nombre = "juani sbaraglia"
      juani.nota = Nota.new
      juani.nota.valor = 9
      juani.save!
      pepito.nombre = "Pepito Maldonado"
      pepito.nota = juani.nota
      pepito.nota.valor = 10
      pepito.save!
      juani.refresh!
      expect(juani.nota.valor).to eq 10
    end

    it 'El atributo compuesto puede ser refrescado desde otro objeto' do
      pepito = Estudiante.new
      juani = Estudiante.new
      juani.nombre = "juani sbaraglia"
      juani.nota = Nota.new
      juani.nota.valor = 5
      juani.save!
      pepito.nombre = "Pepito Maldonado"
      pepito.nota = juani.nota
      pepito.nota.valor = 6
      pepito.save!
      juani.nota.valor = 4
      juani.save!
      pepito.refresh!
      expect(pepito.nota.valor).to eq 4
    end


    it 'El atributo compuesto tiene la misma referencia que otro atributo compuesto con el mismo objeto' do
      jose = Estudiante.new
      jose.nombre = "jose sbaraglia"
      nota = Nota.new
      nota.valor = 8
      jose.nota = nota
      jose.save!
      paula = Estudiante.new
      paula.nombre = "Paula Sbaraglia"
      paula.nota = nota
      paula.nota.valor = 4
      paula.save!
      jose.refresh!
      expect(jose.nota.valor).to eq 4
    end

    it 'Un objeto compuesto con un objeto no tiene la referencia a este cuando se borra' do
      leo = Estudiante.new
      leo.nombre = "leo sbaraglia"
      leo.nota = Nota.new
      leo.nota.valor = 8
      leo.save!
      leo.nota.forget!
      leo.refresh!
      expect(leo.nota).to eq nil
    end
  end

  describe 'Composicion con multiples objetos' do
    class Alumno
      has_one String, named: :nombre
      has_many Nota, named: :notas
    end

    it 'un objeto con un atributo compuestos con multiples objetos sin asignar devuelve una lista vacia' do
      tomas = Alumno.new
      tomas.nombre = "tomas sbaraglia"
      expect(tomas.notas).to eq []
    end

    it 'Un objeto con atributo compuestos con multiples objetos devuelve la lista de objetos' do
      guido = Alumno.new
      guido.nombre = "Guido Bevilacqua"
      unaNota = Nota.new
      otraNota = Nota.new
      guido.notas.push(unaNota)
      guido.notas.last.valor = 8
      guido.notas.push(otraNota)
      guido.notas.last.valor = 5
      guido.save!
      expect(guido.notas).to eq [unaNota, otraNota]
    end

    it 'Un objeto con atributo compuestos con multiples objetos refrescados devuelve la lista de objetos guardada' do
      guido = Alumno.new
      guido.nombre = "Guido Bevilaqua"
      unaNota = Nota.new
      otraNota = Nota.new
      guido.notas.push(unaNota)
      guido.notas.last.valor = 8
      guido.notas.push(otraNota)
      guido.notas.last.valor = 5
      guido.save!
      guido.notas.push(Nota.new)
      guido.refresh!
      expect(guido.notas.map{|x| x.id}).to eq [unaNota.id, otraNota.id]
    end

    it 'Un objeto compuesto con otros objetos no tiene la referencia a esos objetos cuando se borran' do
      guido = Alumno.new
      guido.nombre = "Guido Bevilaqua"
      unaNota = Nota.new
      otraNota = Nota.new
      guido.notas.push(unaNota)
      guido.notas.last.valor = 8
      guido.notas.push(otraNota)
      guido.notas.last.valor = 5
      guido.save!
      unaNota.forget!
      otraNota.forget!
      guido.refresh!
      expect(guido.notas.empty?).to eq true
    end

  end

  describe 'validate!' do

    it 'No se puede guardar un objeto persistente con un valor de tipo diferente al declarado para un objeto con atributos simples' do
      juan = Student.new
      juan.full_name = 5
      expect{juan.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto persistente si los tipos coinciden' do
      cande = Estudiante.new
      cande.nombre = "Cande Sierra"
      cande.nota = Nota.new
      cande.nota.valor = 10
      cande.save!
      expect(cande.id).not_to eq nil
    end

    it 'No se puede guardar un objeto persistente con composición si los tipos no coinciden' do
      tom = Estudiante.new
      tom.nombre = "Thomas Marlow"
      tom.nota = Nota.new
      tom.nota.valor = "Diez"
      expect{tom.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto persistente con atributos complejos si los tipos coinciden' do
      ara = Alumno.new
      ara.nombre = "Ara"
      unaNota = Nota.new
      otraNota = Nota.new
      ara.notas.push(unaNota)
      ara.notas.last.valor = 8
      ara.notas.push(otraNota)
      ara.notas.last.valor = 5
      ara.save!
      expect(ara.id).not_to eq nil
    end

  end

  describe 'Validacion no_blank' do
    class Bird
      has_one String, named: :name, no_blank: true
    end


    class Birds
      has_many String, named: :names, no_blank: true
    end



    it 'No se puede guardar un objeto si tiene un atirbuto vacío' do
      juancito = Bird.new
      juancito.name = ""
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'No se puede guardar un objeto si tiene un atirbuto nulo' do
      juancito = Bird.new
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'Se puede guardar un objeto si no tiene un atirbuto nulo' do
      juancito = Bird.new
      juancito.name = "Juancito De Las Nieves"
      juancito.save!
      expect(juancito.id).not_to eq nil
    end

    it 'No se puede guardar una coleccion que tiene objetos vacíos o nil' do
      juancito = Birds.new
      juancito.names.push("Juan")
      juancito.names.push("")
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'No se puede guardar una coleccion que tiene objetos vacíos o nil' do
      juancito = Birds.new
      juancito.names.push("Juan")
      juancito.names.push(nil)
      expect{juancito.save!}.to raise_error 'The instance can not be nil nor empty'
    end

    it 'Se puede guardar una coleccion tiene que objetos vacíos o nil' do #TODO no pasa porque el save! no guarda objetos no persistibles
      juancito = Birds.new
      juancito.names.push("Juan")
      juancito.names.push("Jorge")
      juancito.save!
      expect(juancito.id).not_to eq nil
    end


  end

  describe 'Validacion from' do
    class Bird
      has_one Numeric, named: :age, from: 5, to: 20
    end

    class Dog
      has_many Numeric, named: :numerosFavoritos, from:0, to:100
    end

    it 'No se puede guardar un obejeto si tiene una colecciones de objetos con valor menor al minimo requerido' do
      tiff = Dog.new
      tiff.numerosFavoritos.push(5)
      tiff.numerosFavoritos.push(-2)
      expect{tiff.save!}.to raise_error 'The instance can not be smaller than the minimum required'
    end

    it 'No se puede guardar un obejeto si tiene una colecciones de objetos con valor mayor al maximo requerido' do
      tiff = Dog.new
      tiff.numerosFavoritos.push(5)
      tiff.numerosFavoritos.push(200)
      expect{tiff.save!}.to raise_error 'The instance can not be bigger than the maximum required'
    end

    it 'Se puede guardar un objeto si una coleccion de objetos con valor mayor al minimo requerido' do #TODO no pasa porque no anda el save
      tiff = Dog.new
      tiff.numerosFavoritos.push(5)
      tiff.numerosFavoritos.push(99)
      tiff.save!
      expect(tiff.id).not_to eq nil
    end

    it 'No se puede guardar un objeto si tiene un valor menor al minimo requerido' do
      nala = Bird.new
      nala.name = "Nala"
      nala.age = 2
      expect{nala.save!}.to raise_error 'The instance can not be smaller than the minimum required'
    end

    it 'Se puede guardar un objeto si tiene un valor mayor al minimo requerido' do
      alekai = Bird.new
      alekai.name = "Alekai"
      alekai.age = 6
      alekai.save!
      expect(alekai.id).not_to eq nil
    end

    it 'No se puede guardar un objeto si tiene un valor mayor al maximo requerido' do
      olivia = Bird.new
      olivia.name = "Olivia"
      olivia.age = 50
      expect{olivia.save!}.to raise_error 'The instance can not be bigger than the maximum required'
    end
  end

  describe 'Validacion por bloque' do

    class Toy
      has_one String, named: :name
    end

    class Cat
      has_many Toy, named: :toys, validate: proc{name.length > 4}
    end

    it 'Se puede guardar un objeto con composicion simple si cumple con la condición del bloque' do
      mora = Cat.new
      voleyball = Toy.new
      voleyball.name = "Voleyball ball"
      mora.toys.push(voleyball)
      mora.save!
      expect(mora.id).not_to eq nil
    end

    it 'No se puede guardar un objeto con composicion simple si no cumple con la condición del bloque' do
      mora = Cat.new
      ball = Toy.new
      ball.name = "Ball"
      mora.toys.push(ball)
      expect {mora.save!}.to raise_error 'The instance has invalid values'
    end

    it 'No se puede guardar un objeto si no cumple con la condición del bloque' do
      mora = Cat.new
      ball = Toy.new
      voleyball = Toy.new
      voleyball.name = "Voleyball ball"
      ball.name = "Ball"
      mora.toys.push(ball)
      mora.toys.push(voleyball)
      expect {mora.save!}.to raise_error 'The instance has invalid values'
    end

    it 'Se puede guardar un objeto compuesto si cumple con la condición del bloque' do
      mora = Cat.new
      ball = Toy.new
      voleyball = Toy.new
      voleyball.name = "Voleyball ball"
      ball.name = "Balls"
      mora.toys.push(ball)
      mora.toys.push(voleyball)
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

  describe "Herencia" do

    module Legajo
      has_one Numeric, named: :legajo
    end

    module Address
      has_one String, named: :street
      has_one Numeric, named: :number
    end

    class Person
      include Legajo
    end

    class Employe < Person
      include Address
      has_one String, named: :role
      has_one Boolean, named: :has_childrend
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

    let(:juan){Person.new}
    let(:juan_boss){Employe.new}


    it 'se deberia persistir la clase que incluye un module persistible' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_childrend = false
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
      juan_boss.has_childrend = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(Employe.all_instances).not_to eq([])
    end

    it 'all_instance de superclse debe traer todas las instacias de las subclases' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_childrend = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(Person.all_instances.size).to eq(2)
    end

    it 'find_by en superclase debe traer elementos de subclases' do
      juan_boss.role = "Boss"
      juan_boss.first_name = "Juan"
      juan_boss.last_name = "Perez"
      juan_boss.legajo = 123456
      juan_boss.street = "Calle Falsa"
      juan_boss.number = 123
      juan_boss.has_childrend = false
      juan_boss.save!

      juan.first_name = "Juan"
      juan.last_name = "Perez"
      juan.legajo = 123456
      juan.save!
      expect(Person.all_instances.size).to eq(2)
    end
    #TODO agregar test por dos clases que incluyan un mismo modulo

    it 'find_by en modulos incluidos en varias clases debe traer solo los elementos de la clase solicitada' do
      m = Manager.new
      m.number = 123
      m.next_meeting = "Monday"
      m.save!

      a = Assistant.new
      a.number = 211
      a.name = "Juan"
      a.save!

      expect(Manager.all_instances.size).to eq(1)
      expect(Assistant.all_instances.size).to eq(1)
      expect(Phone.all_instances.size).to eq(2)
    end
  end
end