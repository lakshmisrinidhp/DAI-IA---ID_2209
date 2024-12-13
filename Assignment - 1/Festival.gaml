///***
//* Name: FestivalSimulation
//* Author: Lakshmi Srinidh Pachabotla
//* Description: Simulation of a festival environment where guests search for food and drinks
//* using directions from an information center
//***/

model FestivalSimulation

global {
    init {
        seed <- 20.0;  // Set random seed for reproducibility
        bool switchFlag <- true;

        // Create FestivalGuests with random locations
        create FestivalGuest number: 20 {
            location <- {rnd(100), rnd(100)};
        }

        // Create Stores with alternating types (FOOD/WATER) and random locations
        create Store number: 6 {
            location <- {rnd(100), rnd(100)};
            if (switchFlag) {
                color <- #blue;  // Water stores are blue
                type <- "WATER";
                switchFlag <- false;
            } else {
                color <- #red;  // Food stores are red
                type <- "FOOD";
                switchFlag <- true;
            }
        }

        // Create a single InformationCenter at a fixed location
        create InformationCenter number: 1 {
            location <- {50, 50};
        }
    }
}

species Store {
    string type <- "FOOD";  // Can be "FOOD" or "WATER"
    rgb color <- #white;

    aspect default {
        draw cube(8) at: location color: color;
    }
}

species InformationCenter {
    list<Store> waterStores <- nil;
    list<Store> foodStores <- nil;

    init {
        ask Store {
            if (self.type = "WATER") {
                myself.waterStores << self;
            } else if (self.type = "FOOD") {
                myself.foodStores << self;
            }
        }
    }

    aspect default {
        draw pyramid(15) at: location color: #black;
    }
}

species FestivalGuest skills: [moving] {
    int thirst <- rnd(1000);
    int hunger <- rnd(1000);
    rgb guestColor <- #green;
    point infoCenterLocation <- {50, 50};
    Store destinationStore <- nil;

    // Move towards store to satisfy thirst or hunger
    reflex moveToStore when: (destinationStore != nil) {
        write "Heading to Store";
        do goto target: destinationStore;

        // Reset thirst/hunger upon reaching store
        ask Store at_distance 2 {
            if (myself.thirst >= 500 and self.type = "WATER") {
                myself.thirst <- 0;
                write "Thirst satisfied at Water store.";
            } else if (myself.hunger >= 500 and self.type = "FOOD") {
                myself.hunger <- 0;
                write "Hunger satisfied at Food store.";
            }
        }

        // Reset destination if needs are met
        if (thirst < 500 and hunger < 500) {
            destinationStore <- nil;
            guestColor <- #green;
        }
    }

    // Wander idly when not thirsty or hungry
    reflex idleWander when: destinationStore = nil and thirst < 500 and hunger < 500 {
        write "Wandering...";
        guestColor <- #green;
        do wander;
    }

    // Go to InformationCenter if thirsty or hungry
    reflex visitInfoCenter when: (hunger >= 500 or thirst >= 500) and destinationStore = nil {
        write "Heading to Information Center";
        do goto target: infoCenterLocation;
        ask InformationCenter at_distance 2 {
            if (myself.thirst >= 500) {
                int index <- rnd(length(self.waterStores) - 1);
                myself.destinationStore <- self.waterStores[index];
                myself.guestColor <- #blue;
            } else if (myself.hunger >= 500) {
                int index <- rnd(length(self.foodStores) - 1);
                myself.destinationStore <- self.foodStores[index];
                myself.guestColor <- #red;
            }
        }
    }

    // Gradually increase thirst or hunger
    reflex increaseNeeds {
        if (destinationStore = nil) {
            if (thirst < 500) {
                thirst <- thirst + 2;
            } else if (hunger < 500) {
                hunger <- hunger + 2;
            }
        }
    }

    aspect default {
        draw sphere(2) at: location color: guestColor;
    }
}

experiment main type: gui {
    output {
        display map type: opengl {
            species FestivalGuest;
            species Store;
            species InformationCenter;
        }
    }
}
