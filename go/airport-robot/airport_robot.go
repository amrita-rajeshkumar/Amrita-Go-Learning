package airportrobot

import "fmt"

// Write your code here.
// This exercise does not have tests for each individual task.
// Try to solve all the tasks first before running the tests.

type Greeter interface {
	LanguageName () string
	Greet(visitor_name string) string

}


func SayHello(visitor_name string, g Greeter) string{

	return fmt.Sprintf("I can speak %s: %s",g.LanguageName(),g.Greet(visitor_name))
}

// Italian

type Italian struct{}

func (i Italian) LanguageName() string{
return "Italian" 
}

func (i Italian) Greet (visitor_name string) string {
	return fmt.Sprintf("Ciao %s!",visitor_name)
}

//Portuguese


type Portuguese struct{}

func (p Portuguese) LanguageName() string {
	return "Portuguese"
}

func (p Portuguese) Greet(visitor_name string) string {
	return fmt.Sprintf("Olá %s!",visitor_name)
}
