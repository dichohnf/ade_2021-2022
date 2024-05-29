.data 
#L'ordine degli store delle seguenti parole e stringhe non e` casuale.
#Nonostante sia indifferente l'ordine in cui si inseriscono le chiavi di criptazoine e la stringa contenente la sequenza delle codifiche da applicare,
#risulta comunque fondamentale mantenere come ultimo campo, all'interno della sezione .data, la stringa da cifrare.
#Infatti, nella funzione cifratura "occorrenze", la stringa viene mutata e la funzione sovrascrivera` anche il contenuto dei byte successivi al null-char della stringa originale, indipendentemente dal loro contenuto. 

blocKey: .string "OLE ole ale ALE !!!"
sostK: .word -765
mycypher: .string "AED"                #Stringa specificatrice della sequenza di codifiche. Nei commennti apparira` brevemente come "stringa di sequenza"
myplaintext: .string "Ciao Mondo!"

.text
#Il programma si divide in due parti.
#La prima sezione contenente esclusivamente la funzione main, che dettera` la direzione del flusso del PC,
#La seconda sezione invece contiene le funzioni utilizzate internamente al main.
#Le funzioni chiamate dal main sono di 3 tipologie: calcolo dell'indirizzo del null-char delle stringhe, stampa delle stringhe e codifica/decodifica delle stringhe. (per l'elelnco integrale delle funzioni vedi la sezione adibita)


#I nomi delle sezioni di codice seguono uno schema predefinito:
#    NomeDellaFunzioneDiAppartenenza_SezioneInternaDellaFunzione_SpecificazioneDelleOperazioniSvolteInternamente
#Alle volte sono stati assegnati dei nomi ad alcuni indirizzi del programma che non vengono utilizzati nello stesso per i salti.
#Il motivo dell'inserimento di questi e` dato da una maggiore leggibilita` che il programma ottiene con la loro presenza.

main:
#STORES PROPEDEUTICI: si salvano nei registri statici tutte le informazioni utili per lo svolgimento del main
    la   s0, myplaintext               #s0 = Indirizzo myPlainText        
    mv   a0, s0                   
    jal  calcStringEnd
    mv   s1, a0                        #s1 = indirizzo null-char myPlainText

    lw   s2, sostK                     #s2 = chiave per la cifratura monoalfabetica (cifrario di Cesare)


    la   s3, blocKey                   #s3 = indirizzo stringa di cifratura per il cifrario a blocchi
    mv   a0, s3                        
    jal  calcStringEnd
    mv   s4, a0                        #s4 = null-char della stringa di cifratura per il cifrario a blocchi


    la   s5, mycypher                  #s5 = indirizzo della stringa specificatrice della sequenza di codifiche
    mv   a0, s5
    jal  calcStringEnd
    mv   s6, a0                        #s6 = null-char della stringa di sequenza

#La main_loop e` la sezione di codice in cui si esegue il ciclo sulla stringa di sequenza e le conseguenti chiamate alle funzioni di cifratura
#Inizialmente si esegue uno scorrimento da sinistra a destra, per eseguire la cifratura, una volta giunti al null-char si procede in senso inverso finche` non si torna all'indirizzo iniziale di mycypher
main_loop_setup:
    mv   a0, s0
    mv   a1, s1
    mv   s7, s5                        #s7 = indirizzo che "cicla" sulla stringa di sequenza, indica il prossimo byte della mycypher da caricare
    li   s10, 0                        #s10 = falg che seleziona codifica o decodifica

#Per comprimere il codice ed evitare ripetizioni dello stesso e` stato identificato un flag, che viene controllato ad ogni ciclo, per identificare se e` necessario codificare o decodificare.
#Questo aggiunge una circa un numero di istruzioni equivalente a 2 volte il numero di byte di mycypher, pero` evita la riscrittura di nuoba parte del main_loop
main_loop:
    bne  s10, zero, main_loop_decode

#Il ciclo che chiama le funzioni di codifica si interrompe appena l'indirizzo s7 raggiunge il null-char di mycypher
main_loop_encode:
    bge  s7, s6, main_loop_decode_setup
    jal  printString
    lbu  s8, 0(s7)
    addi s7, s7, 1 
    j    main_loop_selection

#Nel main_loop_decode_setup si esegue solo il cambio al valore di flag. Questa istruzione viene eseguita un'unica volta, quando si esce da main_loop_encode
main_loop_decode_setup:
    li   s10, 1

#Il ciclo chiamante delle funzioni di decodifica si interrompe appena s7 giunge all'indirizzo di mycypher - 1.
#Finito questo ciclo si ottiene una stringa identica a myplaintext
main_loop_decode:
    addi s7, s7, -1
    jal  printString
    blt  s7, s5, end_main
    lbu  s8, 0(s7)

#Albero di scelta della funzione da chiamare.
#Viene utilizzata una struttura ad albero per la selezione del valore
main_loop_selection:
    li   s9, 67                        #ASCII(C) = 67
    beq  s8, s9, main_codeCcall
    bgt  s8, s9, 24
    
    addi s9, s9, -1                    #ASCII(B) = 66
    beq  s8, s9, main_codeBcall
    
    addi s9, s9, -1                    #ASCII(A) = 65
    beq  s8, s9, main_codeAcall
    
#Il flusso giunge a questa istruzione (e alla gemella a PC + 20) solo se il contenuto del byte caricato da mycypher non appartiene al set di valori legali {A, B, C, D, E}
    j    end_main
    
    addi s9, s9, 1                     #ASCII(D) = 68
    beq  s8, s9, main_codeDcall
    
    addi s9, s9, 1                     #ASCII(E) = 69
    beq  s8, s9, main_codeEcall
    
    j    end_main
    
#Chiamate alle funzioni di codifica con relativi setup e aggiustamenti finali   
main_codeAcall:
    mv   a2, s2                        #Caricamento di sostK
    mv   a3, s10                       #Caricamento del selezionatore per codifica e decodifica
    jal  codeA
    j    main_loop

main_codeBcall:
    mv   a2, s3                        #Caricamento indirizzo blocKey
    mv   a3, s4                        #Caricamento indirizzo null-char di blocKey
    mv   a4, s10                       #Caricamento del selezionatore di codifica e decodifica
    jal  codeB
    j    main_loop 

main_codeCcall:
    beq  s10, zero, 12
    jal  decodeC
    j    main_codeCcall_end
    jal  codeC
    
#La funzione codeC (cifrario Occorrenze) e` l'unica che muta, sia in codifica che decodifica, la lunghezza della stringa che deve quindi essere cambiata nel main dopo ogni chiamata.    
main_codeCcall_end:
    mv   s1, a0                        #Aggiornamento del null-char della stringa da codificare
    mv   a1, s1
    mv   a0, s0
    j    main_loop
   
main_codeDcall:
    jal  codeD
    j    main_loop   
    
main_codeEcall:
    jal  codeE
    j    main_loop 

end_main:
    li   a7, 10                        #10 -> terminazione programma
    ecall

#SEZIONE DELLE FUNZIONI
#La presente sezione contiene le seguenti funzioni:
#    (1) codaA = cifrario per Sostituzione
#    (2) codeB = cifrario a Blocchi
#    (3) codeC = cifratura "Occorrenze"
#    (4) decodeC = decifratura "Occorrenze"
#    (5) codeD = cifratura "Dizionario"
#    (6) codeE = cifratura "Inversione"
#    (7) calcStringEnd = calcolo null-cahr della stringa
#    (8) printString = stampa della stringa seguita da capoverso


#CIFRARIO A SOSTITUZIONE (o CIFRARIO DI CESARE) (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da codificare/decodificare
#a1 = null-char della stringa da codificare/decodificare
#a2 = sostK
#a3 = selezionatore di codifica o decodifica
#Non restituisce niente. Tuttavia a0, al momento del return, risultera` sempre l'indirizzo della stringa codificata, identico a quello passato inizialmente.
#Il codice esegue la somma del valore della sostK al contenuto di ogni byte della stringa che contiene un valore corrispondente ad una lettera in codifica ASCII ([65, 90] e [97, 122]) ed esegue il modulo del risultato affinche` la traslazione avvenga ciclicamente all'interno del sottogruppo di appartenenza della lettera (maiuscole o minuscole)
#La funzione esegue sia codifica che decodifica.
codeA:
        mv   t0, a0                    #Reset indirizzo puntatore al prossimo byte di cui caricare il contenuto
        li   t1, 26                    #Load del valore 26, utile perche` la somma sia modulata sul numero di lettere dell'alfabeto
        rem  a2, a2, t1                #Calcolo del modulo di sostK (per 26)
        beqz a3, 8                     #Selezione codifica o decodifica.
        neg  a2, a2                    #Calcolo del complementare di sostK modulato per 26
        bgez a2, codeA_loop            #Se codeKey modulata è negativa si calcola il corrispondente valore appartenente a [0,25], aggiungendo 26.
        add  a2, a2, t1

#Il ciclo interno del cifrario a sostituzione esegue una load del byte puntato da t0, incrementa il contenuto di t0 di 1, perche` punti al byte successivo ed esegue un controllo sul valore appena caricato.
#Se questo valore corrisponde ai valori ASCII equivalenti a lettere allora esegue la cifratura. Se il valore non corrisponde ad una lettera ASCII allora si esegue il prossimo passo del ciclo.
#Questo termina quando t0 punta al null-char della stringa da codificare.
codeA_loop:
        bge  t0, a1, end_codeA
        lbu  t3, 0(t0)
        addi t0, t0, 1
    
        li   t2, 65
        blt  t3, t2, codeA_loop        #Se t2 < ASCII(A) allora non viene cifrato
        li   t2, 122
        bgt  t3, t2, codeA_loop        #Se t2 > ASCII(z) allora non viene cifrato
        li   t2, 90
        bgt  t3, t2, 12                #Se t2 > ASCII(Z) allora si controlla se t2 >= ASCII(a) altrimenti si salva in t2 ASCII(A)
        li   t2, 65
        j    codeA_loop_store
        li   t2, 97
        blt  t3, t2, codeA_loop        #Se t2 >= ASCII(a) allora si carica in t2 ASCII(a), altrimenti il valore contenuto non corrisponde a una lettera.
        
#La seguente sezione calcola la cifratura delle lettere. Viene calcolata la posizione relativa nell'alfabeto (sottraendo il valore di ASCII(a) o di ASCII(A)).
#Viene sommata sostK modulata. Viene sommato il valore di ASCII(a) o ASCII(A) a seconda del contenuto precedente (non viene mutata l'appartenenza al sottogruppo di lettere).
codeA_loop_store:
        sub  t3, t3, t2
        add  t3, t3, a2
        rem  t3, t3, t1        
        add  t3, t3, t2
        
        sb   t3, -1(t0)                #t0 e` stato incrementato dopo il load di t3, quindi la codifica e` relativa al valore precedente rispetto a quello puntato da t0
        j    codeA_loop
    
end_codeA:
        ret
    
#CIFRARIO A BLOCCHI (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da codificare
#a1 = null-char della stringa da codificare
#a2 = indirizzo di blocKey
#a3 = null-char di blocKey
#a4 = selezionatore di codifica o decodifica
#Non restituisce niente. Tuttavia a0, al momento del return, risultera` sempre l'indirizzo della stringa codificata, identico a quello passato inizialmente.
#La funzione somma ad ogni byte della stringa da codificare(/decodificare) il contenuto del byte della blocKey in posizione corrispondente al modulo tra la posizione relativa del byte nella striga da codificare e la lunghezza in byte della codeKey.
#La funzione esegue sia codifica che decodifica.
#Per decodificare viene eseguita un ciclo alternativo nel quale si sottraggono i valori della codeKey ai byte codificati controllando che il valore risultante appartenga all'intervallo [32,127]
codeB:
        li   t0, 0                                        #Reset del contatore sui byte della blocKey 
        li   t1, 96                                       #96 e` il valore a cui verranno modulati i valori
        li   t2, 32                                       #32 e` il valore sotto il quele i caratteri decodificati non sono accettabili
        sub  a3, a3, a2                                   #Si sostittuisce all'indirizzo del null-char di blocKey la lunghezza (in byte) di blocKey

#La funzione esegue, successivamente al setup, un ciclo sui caratteri della blocKey, il quale termina in due situazioni:
#o t0 ha raggiunto la lunchezza della blocKey o la stringa da codificare, essendo piu` corta della blocKey, e` gia` stata interamente codificata.
#Questa sezione di codice e` comune sia alla codifica che alla decodifica.        
codeB_blocKeyLoop:
        bge  t0, a3, end_codeB                            #Interruzione del ciclo se il contatore t0 eguaglia (o supera) la lunghezza in byte della blocKey
                                             
        add  t3, a2, t0                                   #Calcolo dell'indirizzo del byte da caricare della blocKey
        lbu  t3, 0(t3)
 
        add  t4, a0, t0                                   #Calcolo del primo byte della stringa da codificare/decodificare con il valore del byte attualmente caricato della blocKey
        bge  t4, a1, end_codeB                            #Nel caso in cui la stringa da codificare/decodificare sia piu` corta della blocKey si interrompe il ciclo se l'indirizzo appena calcolato risulta pari o successivo al null-char della stringa da codificare
        addi t0, t0, 1                                    #Incremento contatore sulla blocKey
        
        beqz a4, codeB_blocKeyLoop_encodeLoop             #Se il parametro di selezione (a4) e` zero allora si esegue una codifica, altrimenti una decodifica
        addi t3, t3, 32                                   #Per la decodifica si sottrae il valore minimo dell'intervallo di valori in cui si trovano i valori da codificare, ovvero 32.
#La sezione di codice immediatamente successiva e` un ciclo che si interrompe quando non ci sono piu` byte da decodificare con questo valore della blocKey.
#Il valore risultante della decodifica deve appartenere all'intervallo [32,127], quindi la traslazione del valore e` ciclica in questo intervallo (31 == 127).     
codeB_blocKeyLoop_decodeLoop:
        bge  t4, a1, codeB_blocKeyLoop                    #Il ciclo di decodifica si interrompe se t4, il potenziale prossimo indirizzo da decodificare, eguaglia o supera il null-char della stringa
        lbu  t5, 0(t4)                                                       
        sub  t5, t5, t3                                   #Si sottrae il valore caricato dalla blocKey
        
        bge  t5, t2, codeB_blocKeyLoop_decodeLoop_store   #Si somma 96 al valore risultante dalle precedenti sottrazioni finche` non risulta maggiore di 32 (e quindi inferiore o uguale a 127)
        addi t5, t5, 96
        j    -8
        
codeB_blocKeyLoop_decodeLoop_store:        
        sb   t5, 0(t4)                                    #Si salva il valore ottenuto al posto di quello caricato dalla stringa da decodificare
        add  t4, t4, a3                                   #Si calcola il prossimo indirizzo da decodificare con lo stesso valore ottenuto dalla codeKey
        j    codeB_blocKeyLoop_decodeLoop
        
#La sezione di codice immediatamente successiva e` un ciclo che si interrompe quando non ci sono piu` byte da codificare con questo valore della blocKey.
#Il valore risultante della codifica deve appartenere all'intervallo [32,127], quindi la traslazione del valore e` ciclica in questo intervallo (31 == 127).                       
codeB_blocKeyLoop_encodeLoop:
        bge  t4, a1, codeB_blocKeyLoop                    #Il ciclo di codifica si interrompe se t4, il potenziale prossimo indirizzo da decodificare, eguaglia o supera il null-char della stringa
        lbu  t5, 0(t4)
        add  t5, t5, t3                                   #Si somma al valore della stringa appena caricato il valore caricato dalla blocKey
        rem  t5, t5, t1                                   #Si esegue il modulo per 96 della somma dei due valori
        addi t5, t5, 32                                   #Si aggiunge 32 per rientrare nell'intervallo dei valori legali (da 32 a 127 compresi)
        sb   t5, 0(t4)
        add  t4, t4, a3                                   #Si calcola il prossimo indirizzo da codificare con lo stesso valore caricato dalla blocKey
        j    codeB_blocKeyLoop_encodeLoop
end_codeB:
        ret

#FUNZIONE DI CODIFICA PER OCCORRENZE (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da codificare
#a1 = null-char della stringa da codificare
#Restituisce in a0 il nuovo indirizzo del null-char della stringa codificata.
#La funzione esegue inizialmente una copia della stringa da codificare nello stack
#Successivamente cicla su il contenuto dello stack (diminuendo i byte controllati di 1 ad ogni ciclo) e cerca, per ogni valore escluso 129, se esistono dei valori identici nella stringa.
#Se esistono viene inserita la loro posizione relativa all'interno della stringa da codificare nella memoria nella formattazione di "carattere - numero di posizione relativa - ... " . La posizione sara` inserita in modo tale che la stampa a video della stringa codificata restituisca la posizione del carattere.
#Per eseguire questo inserimento si sfrutta nuovamente lo stack.
#Infine si aggiorna il valore di a0 perche` restituisca quanto richiesto.
#Output:
#a0: indirizzo del null-char della stringa codificata
codeC:
        mv   t0, a0                                        #t0 = puntatore al prossimo indirizzo da sovrascrivere
        mv   t1, sp                                        #t1 = indirizzo dello stack all'inizio di questa iterazione di codeC, serve per interrompere il ciclo che avvera` all'interno dello stack

#La sezione di codice immediatamente successiva esegue una copia, in senso inverso, nello stack della stringa da codificare.
#La stringa risultera` scritta nello stack con i caratteri iniziali copiati per ultimi, quindi con i caratteri finali della stringa nei byte con indirizzi maggiori.
codeC_copyToStack:
        addi a1, a1, -1                                    #aggiornamento del puntatore che indica il byte da copiare
        blt  a1, a0, codeC_setup                           #Il ciclo termina quando a1 punta ad a0 - 1, ovvero quando la stringa e` stata interamente copiata nello stack
        lbu  t2, 0(a1)
        addi sp, sp, -1
        sb   t2, 0(sp)
        j    codeC_copyToStack
    
codeC_setup:
        mv   a3, sp                                        #a3 punta inizialmente al primo carattere della stringa copiata nello stack. orroccre per calcolare la posizione relativa dei byte all'interno della stringa originale.
        li   a4, 45                                        #45 occorre per l'inserimento dei simboli divisori '-'
        li   a5, 32                                        #32 occorre perche` venga eseguito lo store dello spazio, ovvero ASCII(32) = ' '.
        li   a6, 10                                        #10 occorre per l'esecuzione del modulo delle cifre da inserire nella stringa codificata.
        li   a7, 129                                       #129 e` il valore per marcare quali byte sono gia stati inseriti nella stringa codificata (scelto 129 poiche` e` il primo valore della notazione ASCII a non essere associato a nessun carattere).
        j    codeC_loop

#La prossima sezione di codice, codeC-loop, e` un ciclo che termina appena sp assume il suo valore precedente alla copia della stringa codificata, ovvero t1.
#Il ciclo carica il contenuto del byte puntato da sp, registro che scorrera` sulla copia della stringa, e, se questo byte contiene un valore differente da 129 procede all'inserimento del valore stesso nella stringa finale assieme ad un '-' e ne cerchera` le occorrenze, a apartire da quella cosi` trovata.
#Trovate le occorrenze ne` eseguira` lo store nella posizione t0, che punta al prossimo byte da sovrascrivere, e nei byte immediatamente successivi.
#L'inserimento delle occorrenze avverra` inserendo la codifica ASCII delle cifre dell'occorrenza rappresentata in base 10.
codeC_loop:
    
        bge  sp, t1, end_codeC                             #Il ciclo termina quando sp torna nella sua posizione precedente alla chiamata di codeC, ovvero t1.
        lbu  t2, 0(sp)
        addi sp, sp, 1
    
        beq  t2, a7, codeC_loop                            #Se il contenuto del byte e` 129 allora l'occorrenza e` gia` stata segnata e si puo` procedere al prossimo byte.
    
        sb   t2, 0(t0)                                     #Se il contenuto e` diverso da 129 allora e` la prima occorrenza individuata del presente carattere e per questo si inserisce nella stringa codificata.
        addi t0, t0, 1
    
        addi t3, sp, -1                                    #t3 e` un puntatore che cicla all'interno dello stack e che serve per trovare tutte le occorrenze di un dato valore.
    
#La ricerca delle occorrenze avviene nella seguente porzione di codice.
#Se il valore del byte, durante lo scorrimento nello stack, risulta equivalente a quello estratto nel corpo centrale del loop allora calcolo la posizione relativa del byte all'interno della stringa da codificare e inserisco il valore flag al auo interno.
#Occorre una pila per inserire i valori codificati in codice ASCII delle cifre, per cui si utilizza sp.
codeC_loop_searchOccurrences:
        bge  t3, t1, codeC_addSpace                        #Il ciclo termina dopo che t3 ha passato tutto il contenuto dello stack, ovvero quando giunge (o supera) l'indirizzo puntato da t1.
        lbu  t4, 0(t3)
        addi t3, t3, 1
        bne  t4, t2, codeC_loop_searchOccurrences
        sb   a7, -1(t3)                                    #Carico il valore flag perche` non si ripeta l'occorrenza. Non e` piu` necessario che permanga presente nello stack.
        sub  t5, t3, a3                                    #Calcolo della posizione relativa del byte contenente il valore equivalente a quello estratto nel corpo centrale del loop nella stringa da codificare.
        mv   t6, sp                                        #t6 = posizione attuale di sp. Verra` utilizzato per inserire le cifre dell'occorrenza nella stringa codificata. 

#La sezione di codice seguente calcola il modulo per 10 dell'occorrenza e lo inserisce nello stack e divide il numero dell'occorrenza per 10.
#Il ciclo termina quando il numero dell'occorrenza non giunge a zero.
codeC_loop_module:
        ble  t5, zero, codeC_loop_storeHyphen
        rem  a2, t5, a6
        addi sp, sp, -1
        sb   a2, 0(sp)
        div  t5, t5, a6
        j    codeC_loop_module

#Dopo aver calcolato il modulo non rimane altro che eseguire lo store dell'occorrenza.
#Si inserisce innanzi tutto un '-'.
codeC_loop_storeHyphen: 
        sb   a4, 0(t0)
        addi t0, t0, 1

#Si estragono dallo stack i moduli precedentemente calcolati (quindi in ordine inverso rispetto a come calcolati: il corretto ordine di inserimento) e si inseriscono nella stringa codificata.       
#Il ciclo termina quando sp assume il valore precedente al calcolo del modulo
codeC_loop_storeOccurrence:
        bge  sp, t6, codeC_loop_searchOccurrences
        lbu  t5, 0(sp) 
        addi t5, t5, 48                                    #Si aggiunge 48 al modulo perche` corrisponda alla cifra selezionata in codifica ASCII
        sb   t5, 0(t0)
        addi t0, t0, 1
        addi sp, sp, 1
        j    codeC_loop_storeOccurrence

#Al termine di ogni ciclo di ricerca delle occorrenze si inserisce uno spazio  
codeC_addSpace:
        sb   a5, 0(t0)
        addi t0, t0, 1
        j    codeC_loop
    
#Concluso il ciclo principale, la funzione termina eliminando l'ultimo spazio inserito e sostituendolo con un null-char, ovvero uno zero,   
end_codeC:
        addi t0, t0, -1                                    #Eliminazione dell'ultimo spazio inserito e inserimento del carattere null per la terminazione della stringa
        sb   zero, 0(t0)
        mv   a0, t0                                        #Impostazione del valore di output a0, il null-char della stringa codificata.
        ret
        
#FUNZIONE DI DECODIFICA PER OCCORRENZE (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da decodificare
#a1 = null-char della stringa da decodificare
#La funzione scrive nella porzione di memoria immediatamente succesiva alla stringa di codice da codificare la stringa codificate e poi la copia nei byte a seguire da a0.
#Per la decodifica si seleziona ogni carattere nella stringa e si calcola l'indirizzo in cui inserirlo tramite l'occorrenze successive allo stesso carattere.
#Infine si aggiorna il valore di a0 perche` restituisca quanto richiesto.
#Output:
#a0: indirizzo del null-char della stringa codificata 
decodeC:
        mv   t0, a0                                           #t0 = puntatore al prossimo indirizzo di cui caricare il contenuto per la decodifica
        li   a7, 32                                           #ASCII(32) = ' '. Occorrera` per l'interruzione del ciclo interno e quindi l'interruzione degli inserimenti del carattere specifico per il passaggio al carattere successivo.
        li   a6, 45                                           #ASCII(45) = '-'. Occorrera` per il calcolo della posizione relativa in cui inserire il carattere.
        li   a5, 10                                           #Occorrera` per eseguire la moltiplicazione per 10 nel calcolo della posizione relativa dei caratteri.
        mv   a4, a0                                           #Reset di a4 e a3, utili per il calcolo del null-char finale.
        mv   a3, a0                                           #a3 conterra` l'indirizzo piu` alto in cui e` stato inserito un carattere. Il byte successivo sara` quello in cui inserire il null-char della stringa decodificata.

#Il ciclo seguente si divide in tre parti:
#Si carica il carattere da inserire;
#Si calcolano in quali indirizzi inserire il suddetto carattere;
#Si inserisce il carattere nella stringa d'appoggio.
#Il ciclo termina se il puntatore t0, che cicla sulla stringa da codificare, raggiunge il null-char della stessa.
decodeC_loop:
        bleu a4, a3, 8                                        #a3 si aggiorna solo se l'indirizzo in cui e` stato inserito l'ultimo carattere (a4) e` superiore a quella di a3, valore che deve rappresentare il massimo indirizzo raggiunto.
        mv   a3, a4
    
        bge  t0, a1, decodeC_stringCopy_setup
        lbu  t1, 0(t0)                                        #Caricamento del carattere di cui calcoliamo immediatamente la posizione in cui inserirlo
    
        addi t0, t0, 2                                        #Il contenuto sucessivo ad un carattere e` sempre un '-', quindi si salta.
        mv   t2, zero                                         #t6 conterra` la posizione relativa in cui inserire il carattere

#Il ciclo successivo calcola la posizione relativa (rispetto al primo elemento della stringa) in cui si trova il carattere nella stringa decodificata.
decodeC_loop_searchCharPositions:
        lbu  t3, 0(t0)                                        
        ble  t3, a6, decodeC_loop_storeChar                   #Se il valore nel byte e` 45, 32 o 0 (gli unici valori possibili oltre a una cifra, che appartengono all'intervallo [48,57]) il ciclo si interrompe. 
        
        mul  t2, t2, a5                                       #Si moltiplica t6 per 10.
        addi t3, t3, -48                                      #Si sottrae la parte di codifica ASCII dal byte caricato (ASCII(48) = '0').
        add  t2, t2, t3                                       #Si somma a t6 il valore della cifra contenuta nel byte caricato.
        addi t0, t0, 1
        j    decodeC_loop_searchCharPositions

#La sezione di codice succssiva esegue lo store del carattere nella posizione della stringa d'appoggio corretta.    
decodeC_loop_storeChar:
                                                              
        add  a4, a1, t2                                       #La posizione relativa inizia il conteggio da 1, quindi l'indirizzo iniziale della stringa d'appoggio risulta quello successivo ad a1, null-char della stringa da decodificare.
        sb   t1, 0(a4)
        addi t0, t0, 1                                   
        ble  t3, a7, decodeC_loop                             #Se t5, il valore caricato per ultimo nel ciclo searchPositions, fosse uno spazio oppure 0 allora si interrompono gli inserimenti del carattere attuale e si passa al successivo carattere.
        mv   t2, zero                                         
        j    decodeC_loop_searchCharPositions                 #Se t5 invece e` diverso da 0 e 32 allora e` un '-': c'e` un'altra occorrenza per lo stesso carattere.

#Il ciclo prossimo copia la stringa da quella ausiliaria alle posizioni da a0 in poi.    
decodeC_stringCopy_setup:
        sb   zero, 1(a3)                                      #Si inserisce il null-char alla fine della stringa d'appoggio.
        mv   t0, a0
        addi t1, a1, 1                                        #Indirizzo iniziale della stringa d'appoggio.
    
decodeC_stringCopy_loop:
        lbu  t2, 0(t1)
        sb   t2, 0(t0)
        beq  t2, zero, end_decodeC                            #Il ciclo termina quando il valore caicato e` uguale al null-char (che viene anch'esso inserito, per ultimo).
        addi t0, t0, 1
        addi t1, t1, 1
        j    decodeC_stringCopy_loop

#Impostazione dell'output e terminazione funzione di codifica.
end_decodeC:
        mv   a0, t0
        ret
    
#FUNZIONE DI CODIFICA E DECODIFICA "DIZIONARIO" (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da codificare
#a1 = null-char della stringa da codificare
#Non restituisce niente. Tuttavia a0, al momento del return, risultera` sempre l'indirizzo della stringa codificata, identico a quello passato inizialmente.
#La funzione cambia solo i valori della stringa relativi a una lettera o a un numero, gli altri valori rimangono immutati
#La funzione sottrae a 187 il valore del contenuto del byte se questo corrisponde a una lettera (ASCII) e a 105 se e` un numero.
#Il risultato e` una stringa con lettere maiuscole al posto delle minuscole, e viceversa, che corrispondono all'equivalente carattere nell'alfabeto invertito (A -> z oppure d ->W)
#Le cifre vengono sostituite dalle cifre complementari rispetto a 9 (2 -> 7, 9 -> 0, ecc)
#Da notare che l'applicazione consecutiva della seeguente funzione equivale ad eseguire una decodifica della stessa, quindi essa e` la stessa funzione di decodifica.
codeD:
        mv   t0, a0                        #t0 = puntatore del prossimo carattere da codificare. Utilizzato per scorrere la stringa da codificare.                     
        li   t3, 187                       #ASCII(A) + ASCII(z) = 187. Il valore occorrera` per la codifica delle lettere.
        li   t4, 105                       #ASCII(0) + ASCII(9) = 105. Il valore occorrera` per la codifica delle cifre.

#Il ciclo seguente scorre i byte della stringa e li carica. Controlla ca quale gruppo appartengono i valori: se lettere, numeri o altro.
#Una volta identificato il gruppo viene eseguita la sottrazione e viene salvato il nuovo valore nella stringa, allo stesso indirizzo da cui si e` caricato il byte.        
codeD_loop:
        bge  t0, a1, end_codeD             #Il ciclo temina se to punta al null-char della stringa da codificare.
        lbu  t1, 0(t0)                     #t1 = contenuto del byte da codificare
        addi t0, t0, 1         

#Seguono una serie di controlli tesi a selezionare la categoria a cui appartiene il byte caricato (lettera, numero, simbolo) e quindi l'operazione da applicarvi.        
codeD_uppercase:
        li   t2, 90                        #90 = ASCII(Z)
        bgt  t1, t2, codeD_lowercase
        li   t2, 65                        #65 = ASCII(A)
        bge  t1, t2, codeD_letterEncode

codeD_number:
        li   t2, 48                        #48 = ASCII(0)
        blt  t1, t2, codeD_loop
        li   t2, 57                        #57 = ASCII(9)
        bgt  t1, t2, codeD_loop            
        sub  t1, t4, t1                    #Codifica dei caratteri numerici
        sb   t1, -1(t0)
        j    codeD_loop       

codeD_lowercase:
        li   t2, 122                       #122 = ASCII(z)
        bgt  t1, t2, codeD_loop
        li   t2, 97                        #97 = ASCII(a)
        blt  t1, t2, codeD_loop
        
codeD_letterEncode:
        sub  t1, t3, t1                    #Codifica caratteri letterali, sia maiuscoli che minuscoli.
        sb   t1, -1(t0)
        j    codeD_loop 
    
end_codeD:
        ret

#FUNZIONE DI CODIFICA E DECODIFICA "INVERSIONE" (metodo mutatore)
#Parametri di input:
#a0 = indirizzo della stringa da codificare.
#a1 = null-char della stringa da codificare.
#Non restituisce niente. Tuttavia a0, al momento del return, risultera` sempre l'indirizzo della stringa codificata, identico a quello passato inizialmente.
#Attraverso due puntatori (sinistra alla testa della stringa e destra alla coda) si scambiano i contenuti dei rispettivi byte fintanto che i due indirizzi non si scambiano di posizione o siano identici.
codeE:
        mv   t0, a0                        #t0 = puntatore di sinistra. 
        mv   t1, a1                        #t1 = puntatore di destra.

#Segue un ciclo nel quale vangono caricati i byte puntati da t0 e t1 e salvati immediatamente in posizioni invertite. Il ciclo termina quando t0 e t1 si scambiano di posizione reciproca.
codeE_loop:                                           
        addi t1, t1, -1                    #Aggiornamento puntatore di destra (svolgere questa istruzione del ciclo precedentemente al branch fa risparmiare il set iniziale).
        bge  t0, t1, end_codeE             #Il ciclo termina quando i puntatori si scambiano o puntano allo stesso byte in memoria
        lbu  t2, 0(t0)            
        lbu  t3, 0(t1)
        sb   t2, 0(t1)
        sb   t3, 0(t0)
        addi t0, t0, 1                     #Aggiornamento puntatore di sinistra
        j    codeE_loop
end_codeE:
        ret

#FUNZIONI AUSILIARIE
#CALCOLO DEL FINE STRINGA o NULL-CHAR (metodo accessore)
#Parametri di input:
#a0 = indirizzo della stringa di cui calcolare l'indirizzo di terminazione.
#Restituisce in a0 l'indirizzo al primo byte contenente zero controllando dall'indirizzo passato in input (se il contenuto dell'indirizzo puntato da a0 e` 0 allora restituisce a0).
#La funzione non utilizza contatori ma svolge un ciclo che esegue esclusivamente un incremento e un controllo sul contenuto di un byte.
calcStringEnd:
calcStringEnd_loop:                            #Il ciclo controlla in ogni byte se il contenuto e' zero, se sì, interrompe gli incrementi.
        lb   t0, 0(a0)
        addi a0, a0, 1
        bne  t0, zero, calcStringEnd_loop
        
end_calcStringEnd:                             #Restituzione indirizzo di chiusura                   
        addi a0, a0, -1
        ret

#FUNZIONE DI STAMPA STRINGA (metodo accessore)
#Parametri di input:
#a0 = indirizzo della stringa da stampare.
#Non restituisce niente. Tuttavia a0, al momento del return, risultera` sempre l'indirizzo della stringa di input, identico a quello passato inizialmente.
#Fa una chiamata a sistema per la stampa della stringa in a0 e la fa seguire dalla stampa di un capoverso.
printString:
        li   a7, 4                             #4 -> stampa stringhe
        ecall
        mv   t0, a0
        li   a0, 10                            #10 = ASCII(capoverso)
        li   a7, 11                            #11 -> stampa carattere
        ecall
        ecall                           
        mv   a0, t0                            #Reimpostazione a0
        ret