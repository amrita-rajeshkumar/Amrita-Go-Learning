package lasagna


//PreparationTime returns the time to prepare based on number of layers
func PreparationTime(layers []string, time_per_layer int) int {
	if time_per_layer == 0 {
		time_per_layer = 2
	}
	return len(layers)*time_per_layer
	panic("a")
}


//Quantities returns the quantity of noodles and sauce required based on number of layers
func Quantities(layers []string) (noodles int, sauce float64) {
	noodle_count:= 0
	sauce_count:= 0
	for i:=0; i<len(layers);i++ {
		if layers[i] == "noodles" {
			noodle_count ++
		}else if layers[i] == "sauce" {
			sauce_count++
		}

	}

	return noodle_count*50, float64(sauce_count)*0.200

}


//AddSecretIngredient modifies myList to replace last item in myList to reflect the same as the last item in friendsList 
func AddSecretIngredient(friendsList, myList []string) {
	myList[len(myList)-1] = friendsList[len(friendsList)-1]
	
}


//ScaleRecipe returns scaled quantities of ingredients to fulfill based on portions required
func ScaleRecipe(quantities []float64, portions int) []float64{
	var scaled_quantities = make([]float64, len(quantities))
	
	for index, qty := range (quantities) {
		scaled_quantities[index] =  qty * float64(portions)/2

	}	
	return scaled_quantities


}
