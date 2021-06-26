import Color.Color
import Tipos.{Apuesta, Dinero, Probabilidad}

trait Juego {
  // TODO saltea chequeo de tiposde getDDPJugadas
  def getDDPApuesta(apuesta : Apuesta) : DDPApuesta = {
    var ddpJugadas = _getDDPJugadas(get_jugadas(apuesta))
    DDPApuesta.sumarRepetidos(ddpJugadas.distribucion.map(_ match {
      case (jugadas, probabilidad) => (jugadas.map(find_jugada(_, apuesta)).sum, probabilidad)
    }))
  }

  private def find_jugada(jugada: Jugada, apuesta: Apuesta): Dinero = { // TODO debe irse
    apuesta.filter(_ match {
      case (jugada_, _) => jugada_ == jugada
    }).map(_ match {
      case (jugada_, dinero_) => dinero_ * jugada_.factorGanancia
    }).sum
  }

  private def get_jugadas(apuesta: Apuesta) : List[Jugada] = { // TODO también debe irse
    apuesta.map(_ match {
      case (jugada_, _) => jugada_
    })
  }

  protected def _getDDPJugadas(jugadas : List[Jugada]) : DDPJugadas = {
    var distribucion = new DDPJugadas(List());
    for (
      suceso <- todosLosSucesos();
      combinacionDeJugadas <- conjuntoPotencia(jugadas)
    ) {
      if (suceso.cumpleConVarias(jugadas, combinacionDeJugadas)) {
        distribucion = distribucion.sumarProbabilidad(combinacionDeJugadas, probabilidadDeSuceso(suceso));
      }
    }
    distribucion;
  }

  def todosLosSucesos() : List[Suceso]

  def probabilidadDeSuceso(suceso : Suceso) : Probabilidad = suceso.peso / pesoDeTodosLosSucesos;

  protected def pesoDeTodosLosSucesos(): Double = todosLosSucesos.map(_.peso).sum

  protected def conjuntoPotencia[A](s: List[A]): List[List[A]] = {
    @annotation.tailrec
    def pwr(s: List[A], acc: List[List[A]]): List[List[A]] = s match {
      case Nil => acc
      case a :: as => pwr(as, acc ::: (acc map (a :: _)))
    }
    pwr(s, Nil :: Nil)
  }
}

object Moneda extends Juego {
  def getDDPJugadas(jugadas : List[JugadaMoneda]) : DDPJugadas = {
    _getDDPJugadas(jugadas)
  }

  def todosLosSucesos() : List[Suceso] = List(
    SucesoMoneda(LadoMoneda.Cara),
    SucesoMoneda(LadoMoneda.Cruz)
  )
}

object Ruleta extends Juego {
  def getDDPJugadas(jugadas : List[JugadaRuleta]) : DDPJugadas = {
    _getDDPJugadas(jugadas)
  }

  def todosLosSucesos() : List[Suceso] = {
    (0 to 36).zip(List[Option[Color]](
      None,
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Rojo),  Some(Color.Negro),
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Rojo),  Some(Color.Negro),
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Rojo),  Some(Color.Negro),
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Negro), Some(Color.Rojo),
      Some(Color.Negro), Some(Color.Rojo),  Some(Color.Negro),
      Some(Color.Rojo),  Some(Color.Negro), Some(Color.Rojo),
    )).map(_ match {
      case (numero, color) =>
        SucesoRuleta(numero, color)
    }).toList
  }
}

