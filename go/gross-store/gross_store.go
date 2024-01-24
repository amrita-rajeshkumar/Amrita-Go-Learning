package gross

// Units stores the Gross Store unit measurements.
func Units() map[string]int {

	units := make(map[string]int)
	
	units["quarter_of_a_dozen"] = 3
	units["half_of_a_dozen"] = 6
	units["dozen"] = 12
	units["small_gross"] = 120
	units["gross"] = 144
	units["great_gross"] = 1728

	return units
}

// NewBill creates a new bill.
func NewBill() map[string]int {
	new_bill := make(map[string]int)
	return new_bill

}

// AddItem adds an item to customer bill.
func AddItem(bill, units map[string]int, item, unit string) bool {
	

	if units[unit] == 0 {
		return false
	} else{
		bill[item] = bill[item] + units[unit]
	
		return true
	}
}

// RemoveItem removes an item from customer bill.
func RemoveItem(bill, units map[string]int, item, unit string) bool {
	if bill[item] == 0 {
		return false
	}

	if units[unit] == 0 {
		return false
	}

	if  bill[item] - units[unit] < 0 {
		return false
	}

	bill[item] = bill[item] - units[unit]

	if bill[item] == 0 {
		delete (bill,item)
	}
			
		return true
	}	



// GetItem returns the quantity of an item that the customer has in his/her bill.
func GetItem(bill map[string]int, item string) (int, bool) {
	if bill[item] == 0 {
		return 0, false
	}
		return bill[item], true
}
