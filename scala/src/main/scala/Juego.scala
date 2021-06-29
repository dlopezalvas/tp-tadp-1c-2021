import Color.{Color, Rojo, Negro}
import Tipos.{Apuesta, Dinero, Peso, Probabilidad}
import Utilidades.conjuntoPotencia

trait Juego {

  // _simularApuestas: obtiene la distribución de probabilidad de las posibles ganancias dada una apuesta compuesta
  protected def _simularApuestas(apuestas : List[Apuesta]) : DistribucionParaApuestas =
    DistribucionParaApuestas.desdeDistribucionParaJugadas(
      _simularJugadas(apuestas map { case (jugada, _) => jugada }),
      apuestas
    )

  // _simularJugadas:
  // obtiene la distribución de probabilidad de los posibles resultados de un conjunto de jugadas simultáneas
  // para eso:
  //    itera por el producto cartesiano entre los sucesos del juego y todos los posibles subconjuntos de jugadas
  //    registrando la probabilidad correspondiente a cada combinacion de jugadas
  //    que sea cumplida (estrictamente) por un suceso
  protected def _simularJugadas(jugadasASimular : List[Jugada]) : DistribucionParaJugadas = {
    var distribucion = new DistribucionParaJugadas(List());
    for (
      suceso <- todosLosPosiblesSucesos();
      posibleCombinacionDeJugadas <- conjuntoPotencia(jugadasASimular)
    ) {
      if (suceso.cumpleEstrictamenteCon(posibleCombinacionDeJugadas, jugadasASimular))
        distribucion = distribucion.incrementarProbabilidadDe(
          posibleCombinacionDeJugadas,
          probabilidadDeSuceso(suceso)
        );
    }
    distribucion;
  }

  def probabilidadDeSuceso(suceso : Suceso) : Probabilidad = suceso.peso / todosLosPosiblesSucesos.map(_.peso).sum;

  // métodos a ser implementados por juegos concretos:
  def todosLosPosiblesSucesos() : List[Suceso]
}


case class Moneda(val pesoCara: Peso, val pesoCruz: Peso) extends Juego {

  // sirven de fachada para asegurar que sólo se simulen jugadas que correspondan al juego Moneda
  def simularJugadas(jugadas : List[JugadaMoneda]) : DistribucionParaJugadas = _simularJugadas(jugadas)
  def simularApuestas(apuestas : List[(JugadaMoneda, Dinero)]) : DistribucionParaApuestas = _simularApuestas(apuestas)

  def todosLosPosiblesSucesos() : List[Suceso] = List(
    SucesoMoneda(LadoMoneda.Cara, pesoCara),
    SucesoMoneda(LadoMoneda.Cruz, pesoCruz)
  )
}


object Ruleta extends Juego {

  // sirven de fachada para asegurar que sólo se simulen jugadas que correspondan al juego Ruleta
  def simularJugadas(jugadas : List[JugadaRuleta]) : DistribucionParaJugadas = _simularJugadas(jugadas)
  def simularApuestas(apuestas : List[(JugadaRuleta, Dinero)]) : DistribucionParaApuestas = _simularApuestas(apuestas)

  def todosLosPosiblesSucesos() : List[Suceso] = {
    val rojo = Some(Rojo)
    val negro = Some(Negro)
    ((0 to 36) zip { List(
      None,
      rojo,   negro,  rojo,
      negro,  rojo,   negro,
      rojo,   negro,  rojo,
      negro,  negro,  rojo,
      negro,  rojo,   negro,
      rojo,   negro,  rojo,
      rojo,   negro,  rojo,
      negro,  rojo,   negro,
      rojo,   negro,  rojo,
      negro,  negro,  rojo,
      negro,  rojo,   negro,
      rojo,   negro,  rojo,
    )} map { case (numero, color) =>
      SucesoRuleta(numero, color)
    }).toList
  }
}

