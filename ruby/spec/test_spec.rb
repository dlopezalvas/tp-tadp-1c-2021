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
  end

  describe 'save!' do
    it 'al guardar un objeto persistible adquiere un atributo persistible @id' do
      persona.first_name = "raul"
      persona.last_name = "porcheto"
      persona.save!
      expect(persona.id.class).to be String
    end

    it 'un objeto persistible sin guardar no tiene un @id' do
      persona.first_name = "raul"
      persona.last_name = "porcheto"
      expect{persona.id}.to raise_error NoMethodError
    end
  end
end