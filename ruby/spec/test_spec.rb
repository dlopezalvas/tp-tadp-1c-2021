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
    it 'un objeto persistible puede cambiar el valor' do
      persona.first_name = "raul"
      expect(persona.first_name).to eq "raul"
    end

    it 'si defino dos atributos con el mismo nombre, el segundo pisa el primero' do
      Person.has_one Boolean, named: :address
      Person.has_one String, named: :address
      persona.address = "Av. San Martin 2567"
      expect(persona.address.class).to be String
    end
  end
end