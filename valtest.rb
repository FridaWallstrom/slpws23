def val()
    print "
    ###########VALIDATE#################
    Vilken test vill du göra?
    Testa mejl [1]
    Testa längd [2]
    Jämföra password [3]
    Bara siffror? [4]
    Stresstest [5]"
  
    input = gets.chomp
    print input
    p input
    puts input
  
    case input
    when "1"
      mejlvalidation()
    when "2"
      lengthvalidation()
    when "3"
      compare()
    when "4"
      check_digits()
    when "5"
      stress_test()
    else
      puts "Du valde ej 1,2 eller 3"
    end
  
    print input
  end
  
  def mejlvalidation()
    print "Skriv mejladress"
    input = gets
    print input
    
    if input.include?("@")
      p "Input är #{input.chomp}"
      p "Innehåller @"
    else
      p "Input är #{input.chomp}"
      p "Innehåller EJ @"
    end
    val()
  end
  
  def lengthvalidation()
    print "Skriv username. Är det för kort?"
    input = gets
    print input
    if input.length <= 2
      p "Input är #{input.chomp}"
      p "Lösenordet är kortare än 2 bokstäver."
    else
      p "Input är #{input.chomp}"
      p "Lösenordet är 2 bokstäver eller längre."
    end
    val()
  end
  
  def compare()
    print "Skriv password för FÖRSTA gången"
    input1 = gets
    print input1
    print "Skriv password för ANDRA gången"
    input2 = gets
    print input2
  
    if input1 == input2
      p "Lösenorden översensstämmer"
    else
      p "Lösenorden översensstämmer ej"
    end
    val()
  end
  
  def check_digits()
    print "Skriv din ålder. Endast siffror?"
    input = gets.chomp
    print input
    answer = input.scan(/\D/).empty? #True om endast siffror eller tom sträng. RegEx: https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html
    if answer == true
      p "Du har skrivit endast siffror (eller tom sträng)"
    else
      p "Du har skrivit tecken som inte är siffror"
    end
    val()
  end
  
  def stress_test()
    tidarray = []
    print "
    Skriv password (1)"
    input1 = gets
    tid1 = Time.now.to_i
    tidarray << tid1
    p tid1
    p tidarray
    
    print "
    Skriv password (2)"
    input2 = gets
    tid2 = Time.now.to_i
    tidarray << tid2
    p tid2
    p tidarray
    
    print "
    Skriv password (3)"
    input3 = gets
    tid3 = Time.now.to_i
    tidarray << tid3
    p tid3
    p tidarray
    #Fortsätt genom att kolla avståndet mellan items i array...
    val()
  
  end
  
  val()
  
  #testa tomma fält (length), samma ord, minst antal ord, splitta godkända tecken.
  
  