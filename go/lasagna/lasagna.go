package lasagna

// import "fmt"
// TODO: define the 'OvenTime' constant
const OvenTime = 40

// RemainingOvenTime returns the remaining minutes based on the `actual` minutes already in the oven.
func RemainingOvenTime(actualMinutesInOven int) int {
	return (OvenTime - actualMinutesInOven)
	panic("RemainingOvenTime not implemented")
}

// PreparationTime calculates the time needed to prepare the lasagna based on the amount of layers.
func PreparationTime(numberOfLayers int) int {
	return (numberOfLayers*2)
	panic("PreparationTime not implemented")
}

// ElapsedTime calculates the time elapsed cooking the lasagna. This time includes the preparation time and the time the lasagna is baking in the oven.
func ElapsedTime(numberOfLayers, actualMinutesInOven int) int {
	return PreparationTime(numberOfLayers)+actualMinutesInOven
	panic("ElapsedTime not implemented")
}


// func main() { 
	
// 	RemainingOvenTime(1)
// 	fmt.Println(RemainingOvenTime(30))
// 	fmt.Println(PreparationTime(1))
// 	fmt.Println(ElapsedTime(1,30))
// }