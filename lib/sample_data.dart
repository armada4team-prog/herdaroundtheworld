// Sample data from the Page 4 designs: 52 Companions and their journeys (real city coordinates).
// Used until The Herd’s Wix site is live (see README → "Test data vs. real data").
import 'models.dart';

List<Companion> sampleCompanions() => [

        Companion(
            number: "0",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            isOriginal: true,
            wish: "see snow on a mountain",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Boulder, CO", latitude: 40.01, longitude: -105.27, when: ""),
                Stop(city: "Denver, CO", latitude: 39.74, longitude: -104.99, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "07",
            glaze: "A8DCC9",
            accent: "D98C86",
            blob: "DDF0E8",
            wish: "see the ocean",
            lastMoved: "3 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, leftBy: "The Herd", when: "Where they were made"),
                Stop(city: "Boulder, CO", place: "Coffee shop near campus", latitude: 40.01, longitude: -105.27, leftBy: "A friend of The Herd", when: "1 month ago", note: "Their first stop out of the studio. Set loose at a coffee shop near campus."),
                Stop(city: "Salt Lake City, UT", latitude: 40.76, longitude: -111.89, when: "1 month ago"),
                Stop(city: "Boise, ID", latitude: 43.62, longitude: -116.2, leftBy: "[TRAVELER 2]", when: "3 weeks ago", note: "I miss this little one already. Boise was lovely to them."),
                Stop(city: "Moab, UT", place: "Bookstore on Main Street", latitude: 38.57, longitude: -109.55, leftBy: "Sam R.", when: "2 weeks ago", note: "Found them on a bookstore shelf and carried them through the arches."),
                Stop(city: "Santa Fe, NM", place: "Café on the plaza", latitude: 35.69, longitude: -105.94, leftBy: "[TRAVELER]", when: "3 days ago", note: "They’re on a café windowsill, watching the street.")
            ],
            travelers: 7
        ),
        Companion(
            number: "2",
            glaze: "F6E3A1",
            accent: "E0B94A",
            blob: "FBF3D6",
            isOriginal: true,
            wish: "ride a train",
            wishGranted: true,
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "Reykjavik", latitude: 64.15, longitude: -21.94, when: ""),
                Stop(city: "Lisbon", latitude: 38.72, longitude: -9.14, when: "1 week ago")
            ],
            travelers: 4
        ),
        Companion(
            number: "3",
            glaze: "D9CCEB",
            accent: "A08BC9",
            blob: "EFE9F7",
            isOriginal: true,
            wish: "meet a dog",
            lastMoved: "3 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: ""),
                Stop(city: "Delhi", latitude: 28.61, longitude: 77.21, when: ""),
                Stop(city: "Tokyo", latitude: 35.68, longitude: 139.65, when: "3 days ago")
            ],
            travelers: 5
        ),
        Companion(
            number: "4",
            glaze: "BFDDF0",
            accent: "7FB2D9",
            blob: "E5F1FA",
            isOriginal: true,
            status: CompanionStatus.quiet,
            wish: "go to a concert",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Mexico City", latitude: 19.43, longitude: -99.13, when: ""),
                Stop(city: "Lima", latitude: -12.05, longitude: -77.04, when: ""),
                Stop(city: "Buenos Aires", latitude: -34.6, longitude: -58.38, when: "2 weeks ago")
            ],
            travelers: 4
        ),
        Companion(
            number: "9",
            glaze: "F7C8AE",
            accent: "F0A27A",
            blob: "FCE9DD",
            status: CompanionStatus.retired,
            wish: "see snow",
            lastMoved: "5 days ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Chicago, IL", latitude: 41.88, longitude: -87.63, when: ""),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: ""),
                Stop(city: "Paris", latitude: 48.86, longitude: 2.35, when: ""),
                Stop(city: "Berlin", latitude: 52.52, longitude: 13.4, when: "5 days ago")
            ],
            travelers: 5
        ),
        Companion(
            number: "10",
            glaze: "A8DCC9",
            accent: "6BBFA3",
            blob: "DDF0E8",
            status: CompanionStatus.adopted,
            wish: "watch a sunrise",
            lastMoved: "4 days ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lisbon", latitude: 38.72, longitude: -9.14, when: ""),
                Stop(city: "Rome", latitude: 41.9, longitude: 12.5, when: ""),
                Stop(city: "Delhi", latitude: 28.61, longitude: 77.21, when: ""),
                Stop(city: "Seoul", latitude: 37.57, longitude: 126.98, when: "4 days ago")
            ],
            travelers: 5
        ),
        Companion(
            number: "17",
            glaze: "EADFD2",
            accent: "C4A27A",
            blob: "F1EAE3",
            wish: "see penguins",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "Marrakesh", latitude: 31.63, longitude: -7.99, when: ""),
                Stop(city: "Nairobi", latitude: -1.29, longitude: 36.82, when: ""),
                Stop(city: "Cape Town", latitude: -33.92, longitude: 18.42, when: "6 days ago")
            ],
            travelers: 5
        ),
        Companion(
            number: "18",
            glaze: "B9C9BF",
            accent: "8FAA9B",
            blob: "E7ECE5",
            wish: "learn to surf",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: ""),
                Stop(city: "Bangkok", latitude: 13.75, longitude: 100.5, when: ""),
                Stop(city: "Bali", latitude: -8.41, longitude: 115.19, when: ""),
                Stop(city: "Sydney", latitude: -33.87, longitude: 151.21, when: "1 week ago")
            ],
            travelers: 5
        ),
        Companion(
            number: "1",
            glaze: "A8DCC9",
            accent: "5FA8A0",
            blob: "DDF0E8",
            isOriginal: true,
            wish: "ride a train",
            lastMoved: "5 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Boise, ID", latitude: 43.62, longitude: -116.2, when: ""),
                Stop(city: "Seattle, WA", latitude: 47.61, longitude: -122.33, when: ""),
                Stop(city: "Portland, OR", latitude: 45.52, longitude: -122.68, when: "5 days ago")
            ],
            travelers: 4
        ),
        Companion(
            number: "12",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            wish: "visit a library",
            wishGranted: true,
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Chicago, IL", latitude: 41.88, longitude: -87.63, when: ""),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "13",
            glaze: "E4C9DD",
            accent: "B07AA1",
            blob: "F6ECF3",
            wish: "meet a dog",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Santa Fe, NM", latitude: 35.69, longitude: -105.94, when: ""),
                Stop(city: "Mexico City", latitude: 19.43, longitude: -99.13, when: "1 week ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "19",
            glaze: "F6E3A1",
            accent: "E0B94A",
            blob: "FBF3D6",
            status: CompanionStatus.waiting,
            wish: "see the ocean",
            lastMoved: "1 day ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Denver, CO", latitude: 39.74, longitude: -104.99, when: "1 day ago")
            ],
            travelers: 2
        ),
        Companion(
            number: "20",
            glaze: "D9CCEB",
            accent: "A08BC9",
            blob: "EFE9F7",
            wish: "ride a train",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Santa Fe, NM", latitude: 35.69, longitude: -105.94, when: ""),
                Stop(city: "Los Angeles, CA", latitude: 34.05, longitude: -118.24, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "21",
            glaze: "BFDDF0",
            accent: "7FB2D9",
            blob: "E5F1FA",
            wish: "meet a dog",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Salt Lake City, UT", latitude: 40.76, longitude: -111.89, when: ""),
                Stop(city: "San Francisco, CA", latitude: 37.77, longitude: -122.42, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "22",
            glaze: "F7C8AE",
            accent: "F0A27A",
            blob: "FCE9DD",
            wish: "see snow",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Santa Fe, NM", latitude: 35.69, longitude: -105.94, when: ""),
                Stop(city: "Austin, TX", latitude: 30.27, longitude: -97.74, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "23",
            glaze: "A8DCC9",
            accent: "6BBFA3",
            blob: "DDF0E8",
            wish: "go to a concert",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Chicago, IL", latitude: 41.88, longitude: -87.63, when: ""),
                Stop(city: "Nashville, TN", latitude: 36.16, longitude: -86.78, when: "1 week ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "24",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            wish: "visit a library",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "Boston, MA", latitude: 42.36, longitude: -71.06, when: "2 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "25",
            glaze: "EADFD2",
            accent: "C4A27A",
            blob: "F1EAE3",
            status: CompanionStatus.waiting,
            wish: "watch a sunrise",
            lastMoved: "3 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Austin, TX", latitude: 30.27, longitude: -97.74, when: ""),
                Stop(city: "Miami, FL", latitude: 25.76, longitude: -80.19, when: "3 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "26",
            glaze: "B9C9BF",
            accent: "8FAA9B",
            blob: "E7ECE5",
            wish: "learn to surf",
            lastMoved: "1 day ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Santa Fe, NM", latitude: 35.69, longitude: -105.94, when: ""),
                Stop(city: "Phoenix, AZ", latitude: 33.45, longitude: -112.07, when: "1 day ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "27",
            glaze: "A8DCC9",
            accent: "5FA8A0",
            blob: "DDF0E8",
            wish: "see the ocean",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Chicago, IL", latitude: 41.88, longitude: -87.63, when: ""),
                Stop(city: "Toronto", latitude: 43.65, longitude: -79.38, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "28",
            glaze: "E4C9DD",
            accent: "B07AA1",
            blob: "F6ECF3",
            wish: "ride a train",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Toronto", latitude: 43.65, longitude: -79.38, when: ""),
                Stop(city: "Montreal", latitude: 45.5, longitude: -73.57, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "29",
            glaze: "F6E3A1",
            accent: "D4A04C",
            blob: "FBF3D6",
            wish: "meet a dog",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Seattle, WA", latitude: 47.61, longitude: -122.33, when: ""),
                Stop(city: "Vancouver", latitude: 49.28, longitude: -123.12, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "30",
            glaze: "F6E3A1",
            accent: "E0B94A",
            blob: "FBF3D6",
            wish: "see snow",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Chicago, IL", latitude: 41.88, longitude: -87.63, when: "1 week ago")
            ],
            travelers: 2
        ),
        Companion(
            number: "31",
            glaze: "D9CCEB",
            accent: "A08BC9",
            blob: "EFE9F7",
            wish: "go to a concert",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: ""),
                Stop(city: "Amsterdam", latitude: 52.37, longitude: 4.9, when: "2 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "32",
            glaze: "BFDDF0",
            accent: "7FB2D9",
            blob: "E5F1FA",
            wish: "visit a library",
            lastMoved: "3 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lisbon", latitude: 38.72, longitude: -9.14, when: ""),
                Stop(city: "Barcelona", latitude: 41.39, longitude: 2.17, when: "3 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "33",
            glaze: "F7C8AE",
            accent: "F0A27A",
            blob: "FCE9DD",
            wish: "watch a sunrise",
            lastMoved: "1 day ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Berlin", latitude: 52.52, longitude: 13.4, when: ""),
                Stop(city: "Prague", latitude: 50.08, longitude: 14.42, when: "1 day ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "34",
            glaze: "A8DCC9",
            accent: "6BBFA3",
            blob: "DDF0E8",
            wish: "learn to surf",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Munich", latitude: 48.14, longitude: 11.58, when: ""),
                Stop(city: "Vienna", latitude: 48.21, longitude: 16.37, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "35",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            wish: "see the ocean",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "Dublin", latitude: 53.35, longitude: -6.26, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "36",
            glaze: "EADFD2",
            accent: "C4A27A",
            blob: "F1EAE3",
            wish: "ride a train",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Amsterdam", latitude: 52.37, longitude: 4.9, when: ""),
                Stop(city: "Copenhagen", latitude: 55.68, longitude: 12.57, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "37",
            glaze: "B9C9BF",
            accent: "8FAA9B",
            blob: "E7ECE5",
            wish: "meet a dog",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Copenhagen", latitude: 55.68, longitude: 12.57, when: ""),
                Stop(city: "Stockholm", latitude: 59.33, longitude: 18.07, when: "1 week ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "38",
            glaze: "A8DCC9",
            accent: "5FA8A0",
            blob: "DDF0E8",
            status: CompanionStatus.quiet,
            wish: "see snow",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: ""),
                Stop(city: "Edinburgh", latitude: 55.95, longitude: -3.19, when: "2 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "39",
            glaze: "E4C9DD",
            accent: "B07AA1",
            blob: "F6ECF3",
            wish: "go to a concert",
            lastMoved: "3 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Paris", latitude: 48.86, longitude: 2.35, when: ""),
                Stop(city: "Munich", latitude: 48.14, longitude: 11.58, when: "3 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "40",
            glaze: "F6E3A1",
            accent: "D4A04C",
            blob: "FBF3D6",
            wish: "visit a library",
            wishGranted: true,
            lastMoved: "1 day ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Paris", latitude: 48.86, longitude: 2.35, when: ""),
                Stop(city: "Rome", latitude: 41.9, longitude: 12.5, when: "1 day ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "41",
            glaze: "F6E3A1",
            accent: "E0B94A",
            blob: "FBF3D6",
            wish: "watch a sunrise",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Rome", latitude: 41.9, longitude: 12.5, when: ""),
                Stop(city: "Istanbul", latitude: 41.01, longitude: 28.98, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "42",
            glaze: "D9CCEB",
            accent: "A08BC9",
            blob: "EFE9F7",
            wish: "learn to surf",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Istanbul", latitude: 41.01, longitude: 28.98, when: ""),
                Stop(city: "Cairo", latitude: 30.04, longitude: 31.24, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "43",
            glaze: "BFDDF0",
            accent: "7FB2D9",
            blob: "E5F1FA",
            wish: "see the ocean",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Tokyo", latitude: 35.68, longitude: 139.65, when: ""),
                Stop(city: "Kyoto", latitude: 35.01, longitude: 135.77, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "44",
            glaze: "F7C8AE",
            accent: "F0A27A",
            blob: "FCE9DD",
            wish: "ride a train",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Kyoto", latitude: 35.01, longitude: 135.77, when: ""),
                Stop(city: "Osaka", latitude: 34.69, longitude: 135.5, when: "1 week ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "45",
            glaze: "A8DCC9",
            accent: "6BBFA3",
            blob: "DDF0E8",
            wish: "meet a dog",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Bangkok", latitude: 13.75, longitude: 100.5, when: ""),
                Stop(city: "Hong Kong", latitude: 22.32, longitude: 114.17, when: "2 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "46",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            wish: "see snow",
            lastMoved: "3 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Bangkok", latitude: 13.75, longitude: 100.5, when: ""),
                Stop(city: "Singapore", latitude: 1.35, longitude: 103.82, when: "3 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "47",
            glaze: "EADFD2",
            accent: "C4A27A",
            blob: "F1EAE3",
            wish: "go to a concert",
            lastMoved: "1 day ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Bangkok", latitude: 13.75, longitude: 100.5, when: ""),
                Stop(city: "Hanoi", latitude: 21.03, longitude: 105.83, when: "1 day ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "48",
            glaze: "B9C9BF",
            accent: "8FAA9B",
            blob: "E7ECE5",
            wish: "visit a library",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lima", latitude: -12.05, longitude: -77.04, when: ""),
                Stop(city: "Rio de Janeiro", latitude: -22.91, longitude: -43.17, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "49",
            glaze: "A8DCC9",
            accent: "5FA8A0",
            blob: "DDF0E8",
            wish: "watch a sunrise",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Mexico City", latitude: 19.43, longitude: -99.13, when: ""),
                Stop(city: "Bogota", latitude: 4.71, longitude: -74.07, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "50",
            glaze: "E4C9DD",
            accent: "B07AA1",
            blob: "F6ECF3",
            wish: "learn to surf",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lima", latitude: -12.05, longitude: -77.04, when: ""),
                Stop(city: "Santiago", latitude: -33.45, longitude: -70.67, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "51",
            glaze: "F6E3A1",
            accent: "D4A04C",
            blob: "FBF3D6",
            wish: "see the ocean",
            lastMoved: "1 week ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lima", latitude: -12.05, longitude: -77.04, when: ""),
                Stop(city: "Cusco", latitude: -13.53, longitude: -71.97, when: "1 week ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "52",
            glaze: "F6E3A1",
            accent: "E0B94A",
            blob: "FBF3D6",
            wish: "ride a train",
            lastMoved: "2 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Sydney", latitude: -33.87, longitude: 151.21, when: ""),
                Stop(city: "Auckland", latitude: -36.85, longitude: 174.76, when: "2 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "53",
            glaze: "D9CCEB",
            accent: "A08BC9",
            blob: "EFE9F7",
            wish: "meet a dog",
            lastMoved: "3 weeks ago",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Sydney", latitude: -33.87, longitude: 151.21, when: ""),
                Stop(city: "Melbourne", latitude: -37.81, longitude: 144.96, when: "3 weeks ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "54",
            glaze: "BFDDF0",
            accent: "7FB2D9",
            blob: "E5F1FA",
            wish: "see snow",
            lastMoved: "1 day ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Marrakesh", latitude: 31.63, longitude: -7.99, when: ""),
                Stop(city: "Lagos", latitude: 6.52, longitude: 3.38, when: "1 day ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "55",
            glaze: "F7C8AE",
            accent: "F0A27A",
            blob: "FCE9DD",
            wish: "go to a concert",
            lastMoved: "2 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Lisbon", latitude: 38.72, longitude: -9.14, when: ""),
                Stop(city: "Marrakesh", latitude: 31.63, longitude: -7.99, when: "2 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "56",
            glaze: "A8DCC9",
            accent: "6BBFA3",
            blob: "DDF0E8",
            wish: "visit a library",
            lastMoved: "4 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "Istanbul", latitude: 41.01, longitude: 28.98, when: ""),
                Stop(city: "Delhi", latitude: 28.61, longitude: 77.21, when: "4 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "57",
            glaze: "F4C7C3",
            accent: "E58FA6",
            blob: "FBE4E2",
            wish: "watch a sunrise",
            lastMoved: "6 days ago",
            movedThisWeek: true,
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made"),
                Stop(city: "New York, NY", latitude: 40.71, longitude: -74, when: ""),
                Stop(city: "London", latitude: 51.51, longitude: -0.13, when: "6 days ago")
            ],
            travelers: 3
        ),
        Companion(
            number: "5",
            glaze: "F4C7C3",
            accent: "D98C86",
            blob: "DDF0E8",
            isOriginal: true,
            status: CompanionStatus.waiting,
            wish: "visit a library",
            lastMoved: "Waiting to be found",
            stops: [
                Stop(city: "Aurora, CO", latitude: 39.73, longitude: -104.83, when: "Where they were made")
            ],
            travelers: 1
        )
    ];
