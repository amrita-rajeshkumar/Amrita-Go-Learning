package booking

import (
	
	"time"

)



// Schedule returns a time.Time from a string containing a date.
func Schedule(date string) time.Time {
	layout := "1/02/2006 15:04:05"
	t,_ := time.Parse(layout,date) 
	return t


}


// HasPassed returns whether a date has passed.
func HasPassed(date string) bool {
	        
	layout := "January 2, 2006 15:04:05"
	scheduled_time, err := time.Parse(layout,date)
	if err != nil {
		panic(err)

	}
	return scheduled_time.Before(time.Now())
}



// IsAfternoonAppointment returns whether a time is in the afternoon.
func IsAfternoonAppointment(date string) bool {
	appointment_date,_ :=time.Parse("Monday, January 2, 2006 15:04:05",date) //Thursday, July 25, 2019 13:45:00
    if (appointment_date.Hour() >= 12 && appointment_date.Hour() <= 18) {
    	return true
    } else {
    	return false
    }

}

// Description returns a formatted string of the appointment time.
func Description(date string) string {
	appointment_date,_ :=time.Parse("1/2/2006 15:04:05",date) //Thursday, July 25, 2019 13:45:00
	formatted_date := appointment_date.Format("Monday, January 2, 2006")
	formatted_time := appointment_date.Format("15:04")
	description:= "You have an appointment on "+formatted_date+", at "+ formatted_time + "."
	return description
}

// AnniversaryDate returns a Time with this year's anniversary.
func AnniversaryDate() time.Time {
	currentYear := time.Now().Year()
	anniversaryDate := time.Date(currentYear, time.September, 15, 0, 0, 0, 0, time.UTC)
	return anniversaryDate
}
