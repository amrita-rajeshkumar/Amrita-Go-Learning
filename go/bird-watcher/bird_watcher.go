package birdwatcher

// TotalBirdCount return the total bird count by summing
// the individual day's counts.
func TotalBirdCount(birdsPerDay []int) int {
	total_bird_count:=0
	for i:=0; i<len(birdsPerDay); i++ {
		total_bird_count=total_bird_count+birdsPerDay[i]
	}
	return total_bird_count
}

// BirdsInWeek returns the total bird count by summing
// only the items belonging to the given week. 3 0 5 1 0 4 1 0 3 4 3 0 8 0
func BirdsInWeek(birdsPerDay []int, week int) int {
	bird_count_in_the_week:=0
	week_start_index := (week-1)*7  // 0,7,14
	week_end_index := week_start_index+6 // 6,13,20
	weeks_present_in_data := len(birdsPerDay)/7
	if week <= weeks_present_in_data{

	for i:=week_start_index; i<=week_end_index; i++ {
		bird_count_in_the_week = bird_count_in_the_week + birdsPerDay[i]
	}
	return bird_count_in_the_week
} else {
	return -1}
}

// FixBirdCountLog returns the bird counts after correcting
// the bird counts for alternate days.
func FixBirdCountLog(birdsPerDay []int) []int {
	for i:=0;i<len(birdsPerDay);i=i+2 {
		birdsPerDay[i]=birdsPerDay[i]+1
	}
	return birdsPerDay
}
