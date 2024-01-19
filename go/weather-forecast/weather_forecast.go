// Package weather package provides current location and current weather condition.
package weather

// CurrentCondition stores the current condition.
var CurrentCondition string

// CurrentLocation atores the current location.
var CurrentLocation string


// Forecast function returns the current location and current weather condition.
func Forecast(city, condition string) string {
	CurrentLocation, CurrentCondition = city, condition
	return CurrentLocation + " - current weather condition: " + CurrentCondition
}
