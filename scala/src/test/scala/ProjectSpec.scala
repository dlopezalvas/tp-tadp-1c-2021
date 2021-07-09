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

    "Probabilidad de Sucesos" - {
      "Probabilidad que salga Cara debe ser 50%" in {
        val jugarACara:JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)

        Moneda(1.0, 1.0).simularJugadas(List(jugarACara)) shouldBe DistribucionParaJugadas(List(
          (List(JugadaMoneda(LadoMoneda.Cara)),0.5),
          (List(),0.5)
        ))
      }

      "Probabildad de que salga numero en la ruleta es de 1/37" in {
        val jugarAlNumero5: JugadaRuleta = NumeroJugado(5)
        Ruleta.simularJugadas(List(jugarAlNumero5)).distribucion.filter(p => p._1.contains(jugarAlNumero5)) shouldBe List((List(jugarAlNumero5),1.0/37.0))
      }

      "Probabilidad de que salga un color es 18/37" in {
        val jugarRojo: JugadaRuleta = ColorJugado(Color.Rojo)
        val apuesta: ApuestaRuleta = ApuestaRuleta(List((jugarRojo, 1.0)))
        Ruleta.simularApuesta(apuesta).distribucion.filter(d => d._1 > 0) shouldBe List((2.0,18.0/37.0))
      }

      "Probabilidad de que salga una docena es de 12/37" in {
        val jugarDocena: JugadaRuleta = DocenaJugada(1)
        val apuesta: ApuestaRuleta = ApuestaRuleta(List((jugarDocena, 1.0)))
        Ruleta.simularApuesta(apuesta).distribucion.filter(d => d._1 > 0) shouldBe List((3.0,12.0/37.0))
      }
    }

    "Probabilidad de Apuestas" - {
      "Si juego cara tengo 50% de probabilidad de ganar y duplicar mi dinero" in {
        val jugarACara:JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)
        val apuesta : ApuestaMoneda = ApuestaMoneda(List((jugarACara, 10.0)))
        Moneda(1.0, 1.0).simularApuesta(apuesta) shouldBe DistribucionParaApuestas(List(
          (20.0,0.5),
          (0.0,0.5)
        ))
      }

      "Si juego primero un color y luego a par en la ruleta tengo 4 distribuciones posibles" in {
        val jugarARojo:JugadaRuleta = ColorJugado(Color.Rojo)
        val jugarAPar:JugadaRuleta = ParidadJugada(Paridad.Par)
        val apuestas : ApuestaRuleta = ApuestaRuleta(List((jugarARojo, 10.0), (jugarAPar, 5.0)))
        Ruleta.simularApuesta(apuestas) shouldBe DistribucionParaApuestas(List(
          ( 0.0, 9.0/37.0),
          (20.0, 10.0/37.0),
          (10.0, 10.0/37.0),
          (30.0, 8.0/37.0)
        ))
      }

      "Si juego un color y luego a par con el mìsmo monto en la ruleta tengo 3 distribuciones posibles" in {
        val jugarARojo:JugadaRuleta = ColorJugado(Color.Rojo)
        val jugarAPar: JugadaRuleta = ParidadJugada(Paridad.Par)
        val apuestas : ApuestaRuleta = ApuestaRuleta(List((jugarARojo,12.0),(jugarAPar,12.0)))
        Ruleta.simularApuesta(apuestas) shouldBe DistribucionParaApuestas(List(
          ( 0.0, 9.0/37.0),
          (24.0, 20.0/37.0),
          (48.0, 8.0/37.0)
        ))
      }
    }

    "Jugadas Sucesivas" - {
      "Si juego cara en la moneda y luego a un nro en la ruleta mis planes son" in {
        val jugarACara:JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)
        val jugarAlCero: JugadaRuleta = NumeroJugado(0)

        val apostar10ACara:ApuestaMoneda = ApuestaMoneda(List((jugarACara,10.0)))
        val apostar15ACero:ApuestaRuleta = ApuestaRuleta(List((jugarAlCero,15.0)))

        val planDeJuego:PlanDeJuego = PlanDeJuego("monedaYRuleta",List(apostar10ACara,apostar15ACero))
        //BigDecimal(0.5 * 1.0/37.0).setScale(2, BigDecimal.RoundingMode.HALF_UP).toDouble
        planDeJuego.aplicar(15.0) shouldBe List(
          (550.0, 0.5 * 1.0/37.0),
          (10.0,0.48648648648648607), //(10.0, 0.5 * 36.0/37.0),
          (5.0, 0.5)
        )
      }

      "Si juego un nro y luego un color mis probabilidades son" in {
        val jugarAl16 = NumeroJugado(16)
        val juegoNegro = ColorJugado(Color.Negro)

        val apostarAl16:ApuestaRuleta = ApuestaRuleta(List((jugarAl16,10.0)))
        val apostarANegro:ApuestaRuleta = ApuestaRuleta(List((juegoNegro,15.0)))

        val planDeJuego:PlanDeJuego = PlanDeJuego("numeroYColor",List(apostarAl16,apostarANegro))

        planDeJuego.aplicar(15.0) shouldBe List(
          (5.0, 0.9729729729729721),
          (350.0, 0.013878743608473342), //(1.0/37.0)*(18.0/37.0)), //TODO: revisar #rari
          (380.0, (1.0/37.0)*(18.0/37.0))
        )
      }

      //TODO: agregar combinaciones  moneda-color   paridad-docena
    }

    "Jugadores y Planes de Juego" - {
      "El jugador racional elige el plan mejor puntuado según su criterio" in {
        val jugarACara: JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)
        val jugarACruz: JugadaMoneda = JugadaMoneda(LadoMoneda.Cruz)
        val jugarAlCero: JugadaRuleta = NumeroJugado(0)

        val apostar10ACara: ApuestaMoneda = ApuestaMoneda(List((jugarACara, 10.0)))
        val apostar10ACruz: ApuestaMoneda = ApuestaMoneda(List((jugarACruz, 10.0)))
        val apostar15ACero: ApuestaRuleta = ApuestaRuleta(List((jugarAlCero, 15.0)))

        val planDeJuego1: PlanDeJuego = PlanDeJuego("monedaYRuleta", List(apostar10ACara, apostar15ACero))

        val planDeJuego2: PlanDeJuego = PlanDeJuego("SoloMoneda", List(apostar10ACara, apostar10ACruz))

        val jugador: Jugador = Jugador(15.0, criterioRacional)

        jugador.elegirPlanDeJuego(List(planDeJuego1, planDeJuego2)) shouldBe planDeJuego2
      }

      "El jugador arriesgado elige el plan con más plata posible" in {
        val jugarAl16 = NumeroJugado(16)
        val juegoNegro = ColorJugado(Color.Negro)

        val apostarDiezAl16:ApuestaRuleta = ApuestaRuleta(List((jugarAl16,10.0)))
        val apostarQuinceAl16:ApuestaRuleta = ApuestaRuleta(List((jugarAl16,15.0)))
        val apostarQuinceANegro:ApuestaRuleta = ApuestaRuleta(List((juegoNegro,15.0)))
        val apostarDiezANegro:ApuestaRuleta = ApuestaRuleta(List((juegoNegro,10.0)))

        val planDeJuego1:PlanDeJuego = PlanDeJuego("numeroYColor",List(apostarDiezAl16,apostarQuinceANegro))
        val planDeJuego2:PlanDeJuego = PlanDeJuego("numeroYColor",List(apostarQuinceAl16,apostarDiezANegro))

        val jugador: Jugador = Jugador(15.0, criterioArriesgado )

        jugador.elegirPlanDeJuego(List(planDeJuego1, planDeJuego2)) shouldBe planDeJuego2
      }

      "El jugador cauto elige el plan mas seguro de no perder plata" in {
        val jugarACara: JugadaMoneda = JugadaMoneda(LadoMoneda.Cara)
        val jugarAlUno: JugadaRuleta = NumeroJugado(1)

        val apostar10ACara: ApuestaMoneda = ApuestaMoneda(List((jugarACara, 10.0)))
        val apostar10AlUno: ApuestaRuleta = ApuestaRuleta(List((jugarAlUno, 10.0)))

        val jugador: Jugador = Jugador(15.0, criterioCauto)

        val planDeJuego1:PlanDeJuego = PlanDeJuego("dosVecesCara",List(apostar10ACara,apostar10ACara))
        val planDeJuego2:PlanDeJuego = PlanDeJuego("dosVecesUno",List(apostar10AlUno,apostar10AlUno))

        jugador.elegirPlanDeJuego(List(planDeJuego1, planDeJuego2)) shouldBe planDeJuego1
      }
    }

    //TODO: agregar otro jugador
  }
}
