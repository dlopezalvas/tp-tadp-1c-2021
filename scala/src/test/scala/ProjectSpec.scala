import Tipos._
import org.scalatest.matchers.should.Matchers._
import org.scalatest.freespec.AnyFreeSpec

class ProjectSpec extends AnyFreeSpec {

  "Jugadas" - {

    "cuando está correctamente configurado" - {
      "debería resolver las dependencias y pasar este test" in {
        1 shouldBe 1
      }
    }

    "Moneda" - {
      "Probabilidad que salga Cara debe ser 50%" in {
        val jugarACara:JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)

        Moneda.getDDPJugadas(List(jugarACara)) shouldBe DistribucionJugada(List(
          (List(JugadaMoneda(LadoMoneda.Cara)),0.5),
          (List(),0.5)
        ))
      }

      "Si juego $10 a cara tengo 50% de probabilidad de ganar $20" in {
        val jugarACara:JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)
        val apuesta:Apuesta = List((jugarACara,10.0))
        Moneda.getDDPApuesta(apuesta) shouldBe DistribucionApuesta(List(
          (20.0,0.5),
          (0.0,0.5)
        ))
      }

      "Si juego $10 a Rojo, $5 a Par en la ruleta" in {
        val jugarARojo:JugadaRuleta = ColorJugado(Color.Rojo)
        val jugarAPar:JugadaRuleta = ParidadJugada(Paridad.Par)
        val apuesta:Apuesta = List((jugarARojo,10.0),(jugarAPar,5.0))
        Ruleta.getDDPApuesta(apuesta) shouldBe DistribucionApuesta(List(
          ( 0.0, 9.0/37.0),
          (20.0, 10.0/37.0),
          (10.0, 10.0/37.0),
          (30.0, 8.0/37.0)
        ))
      }

      "Si juego $12 a Rojo, $12 a Par en la ruleta" in {
        val jugarARojo:JugadaRuleta = ColorJugado(Color.Rojo)
        val jugarAPar:JugadaRuleta = ParidadJugada(Paridad.Par)
        val apuesta:Apuesta = List((jugarARojo,12.0),(jugarAPar,12.0))
        Ruleta.getDDPApuesta(apuesta) shouldBe DistribucionApuesta(List(
          ( 0.0, 9.0/37.0),
          (24.0, 20.0/37.0),
          (48.0, 8.0/37.0)
        ))
      }
    }
  }
}
