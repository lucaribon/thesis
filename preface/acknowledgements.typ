#import "../config/variables.typ" : profTitle, myProf, myLocation, myTime, myName
#import "../config/constants.typ" : acknowledgements

#set par(first-line-indent: 0pt)
#set page(numbering: "i")

#v(10em)

#text(24pt, weight: "semibold", acknowledgements)

#v(3em)

#text(style: "italic", "Innanzitutto, vorrei esprimere la mia gratitudine al " + profTitle + myProf + " relatore della mia tesi, per l'aiuto e il sostegno fornitomi durante tutto il processo di stesura.")

#linebreak()

#text(style: "italic", "Desidero ringraziare con affetto la mia famiglia per il sostegno, il grande aiuto e per essermi stati vicini in ogni momento durante gli anni di studio.")

#linebreak()

#text(style: "italic", "Infine tengo a ringraziare tutti i miei amici per aver contribuito a rendere memorabile ogni momento passato assieme, che fosse di svago o produttivo.")

#v(2em)

#text(style: "italic", myLocation + ", " + myTime + h(1fr) + myName)

#v(1fr)