object Utilidades {
  def conjuntoPotencia[A](s: List[A]): List[List[A]] = {
    @annotation.tailrec
    def pwr(s: List[A], acc: List[List[A]]): List[List[A]] = s match {
      case Nil => acc
      case a :: as => pwr(as, acc ::: (acc map (a :: _)))
    }
    pwr(s, Nil :: Nil)
  }
}
