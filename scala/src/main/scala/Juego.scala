import Color.{Color, Rojo, Negro}
import Tipos.{Dinero, Peso, Probabilidad}
import Utilidades.conjuntoPotencia

trait Juego {

  // _simularApuestas: obtiene la distribución de probabilidad de las posibles ganancias dada una apuesta compuesta
  protected def _simularApuesta(apuesta : Apuesta) : DistribucionParaApuestas =
    DistribucionParaApuestas.desdeDistribucionParaJugadas(
      _simularJugadas(apuesta.apuesta.map(_._1)),
      apuesta.apuesta
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


case class Moneda(pesoCara : Peso, pesoCruz : Peso) extends Juego {

  // sirven de fachada para asegurar que sólo se simulen jugadas/apuestas que correspondan al juego Moneda
  def simularJugadas(jugadas : List[JugadaMoneda]) : DistribucionParaJugadas = _simularJugadas(jugadas)
  def simularApuesta(apuesta : ApuestaMoneda): DistribucionParaApuestas = _simularApuesta(apuesta)
    /*
    TODO: en realidad, a esto de arriba nada te impide pasarle apuestas con pesos distintos a los de la moneda
          ejemplo:  Moneda(1, 1).simularApuesta(ApuestaMoneda(List(JugadaMoneda(LadoMoneda.Cara)), 99, 12213) no tira ningún error
          esto va más allá del sistema de tipos, entonces sin una validación en runtime no se puede evitar.
          así como está, los pesos de la Moneda pisan los pesos de la Apuesta (en el ejemplo de arriba los pesos se evalúan como 1 y 1)
          eso se podría invertir con un if muy feo:
            if (apuesta.pesoCara == pesoCara && apuesta.pesoCruz == pesoCruz)
              _simularApuesta(apuesta)
            else
              Moneda(apuesta.pesoCara, apuesta.pesoCruz)._simularApuesta(apuesta) // o lanzar excepcion
          pero es horrible
          quizás no sea algo tan importante anyway
     */

  def todosLosPosiblesSucesos() : List[Suceso] = List(
    SucesoMoneda(LadoMoneda.Cara, pesoCara),
    SucesoMoneda(LadoMoneda.Cruz, pesoCruz)
  )
}


object Ruleta extends Juego {

  // sirven de fachada para asegurar que sólo se simulen jugadas/apuestas que correspondan al juego Ruleta
  def simularJugadas(jugadas : List[JugadaRuleta]) : DistribucionParaJugadas = _simularJugadas(jugadas)
  def simularApuesta(apuesta : ApuestaRuleta): DistribucionParaApuestas = _simularApuesta(apuesta)

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

