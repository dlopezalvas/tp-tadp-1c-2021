import Color.{Color}
import LadoMoneda.{Cara, Cruz, LadoMoneda}
import Paridad._


trait Suceso{
  def seCumple(resultadoEsperado: ResultadoEsperado): Boolean
}

case class SucesoMoneda(val ladoMoneda: LadoMoneda) extends Suceso {
  override def seCumple(resultadoEsperado: ResultadoEsperado): Boolean = resultadoEsperado match {
    case LadoEsperado(lado) => ladoMoneda.equals(lado)
  }
}

case class SucesoRuleta(val valor: Int, color: Option[Color]) extends Suceso {

  def esPar: Boolean = valor%2 == 0

  def mismaDocena(docena: Int): Boolean = valor/12 == docena + 1

  def seCumple(resultadoEsperado: ResultadoEsperado): Boolean =
    resultadoEsperado match{
      case Numero(numero) => valor == numero
      case Docena(docena) => mismaDocena(docena)
      case ColorEsperado(colorEsperado) => color.equals(colorEsperado)
      case ParidadEsperada(Par) => esPar
      case ParidadEsperada(Impar) => !esPar
      case _ => false
  }

}


case object Sucesos {
  val sucesosRuleta: List[SucesoRuleta] = {
    (0 to 36).zip(List[Option[Color]](
      None,
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Rojo),   Some(Color.Negro),
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Rojo),   Some(Color.Negro),
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Rojo),   Some(Color.Negro),
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Negro),  Some(Color.Rojo),
      Some(Color.Negro),  Some(Color.Rojo),   Some(Color.Negro),
      Some(Color.Rojo),   Some(Color.Negro),  Some(Color.Rojo),
    )).map(t => t match {
      case (numero_, color_) =>
        SucesoRuleta( numero_, color_)
    }).toList
  }

  val sucesosCaraCruz: List[SucesoMoneda] = List(SucesoMoneda(Cara), SucesoMoneda(Cruz))
}
