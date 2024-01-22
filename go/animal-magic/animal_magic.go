package chance

import "math/rand"
// RollADie returns a random int d with 1 <= d <= 20.
func RollADie() int {
	n:= 1
	return n+rand.Intn(20)
}

// GenerateWandEnergy returns a random float64 f with 0.0 <= f < 12.0.
func GenerateWandEnergy() float64 {
	r := 0.0 + rand.Float64() * (12.0 - 0.0)
	return r
}

// ShuffleAnimals returns a slice with all eight animal strings in random order.
func ShuffleAnimals() []string {
	animals := []string{"ant","beaver","cat","dog","elephant","fox","giraffe","hedgehog"}

	rand.Shuffle(len(animals),  func(i, j int) {
								animals[i], animals[j] = animals[j], animals[i]
							})
	return animals
 }