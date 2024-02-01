package parsinglogfiles

import "regexp"
func IsValidLine(text string) bool {
	
re := regexp.MustCompile(`^\[(TRC|DBG|INF|WRN|ERR|FTL)\]`)
return re.MatchString(text)
}

func SplitLogLine(text string) []string {

	re := regexp.MustCompile(`<[~*=-]*>`)
	return re.Split(text, -1)
}

func CountQuotedPasswords(lines []string) int {
	count := 0
	r := regexp.MustCompile(`(?i)".*password.*"`)
	for _, line := range lines {
		if r.MatchString(line) {
			count++
		}
	}
	return count


}

func RemoveEndOfLineText(text string) string {
	re := regexp.MustCompile(`end-of-line\d+`)
	return re.ReplaceAllString(text, "")  
}

func TagWithUserName(lines []string) []string {
	var tagged []string
	re := regexp.MustCompile(`User\s+([A-Za-z0-9]*)`)
	for _, line := range lines {
		submatches := re.FindStringSubmatch(line)
		if submatches != nil {
			tagged = append(tagged, "[USR] "+submatches[1]+" "+line)
		} else {
			tagged = append(tagged, line)
		}
	}
	return tagged
}
