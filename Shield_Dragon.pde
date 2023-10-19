Camera cam;
ArrayList<Actor> actors = new ArrayList<Actor>();
color background = #D6E3EA;
color gridlines = #A6CADE;
boolean prevMousePressed = false;
float ZOOM_SENSITIVITY = 0.01;
int CLICK_DRAG_SENSITIVITY = 5;

int[] clickPosition = {0,0};
boolean mouseDragged = false;
boolean draggingSelection = false;
boolean placeMode = false;
int quantityPlaceMode = 1;
int generationSize = 1000;
boolean assigningShield = false;
boolean assigningDragon = false;
boolean killMode = false;
boolean assignToAll = false;
boolean runGenerationsAuto = false;
int generationCount = 0;

boolean gamePaused = true;
float gameSpeed = 1.0;
long prevTime = millis();
float deltaTime() {
  long now = millis();
  long delta = now - prevTime;
  prevTime = millis();
  return (delta / 1000.0) * gameSpeed;
};

Actor selectedActor = null;

float dragonAttraction = -10000000;
float shieldAttraction = 10000000;

void setup() {
  cam = new Camera();
  cam.centerZoom(1);
  size(800, 500);
}

void draw() {
  update();
  
  background(background);
  drawGrid();
  for (int i = 0; i < actors.size(); i++) {
    color c = #094074;
    Actor actor = actors.get(i);
    if (actor.isMouseHovering() && killMode) {
      c = #550000;
    } else if (selectedActor != null && actor == selectedActor) {
      c = #117EE4;
    } else if (selectedActor != null && actor == selectedActor.shield) {
      c = #00FF00;
    } else if (selectedActor != null && actor == selectedActor.dragon) {
      c = #FF0000;
    } else if (selectedActor != null && selectedActor.getCollidingActors(actors).contains(actor)) {
      c = #F7F052;
    } else if (actor.shieldAndDragonAssigned() && !actor.isSafe()) {
      c = #F29E4C;
    }
  actor.drawActor(c);
  }
  
  if (selectedActor != null && actors.size() >= 3) {
    float[] targetGlobal = selectedActor.getTarget();
    float[] target = cam.convert(targetGlobal[0],targetGlobal[1]);
    fill(#AB54E2);
    circle(target[0], target[1], cam.scaleLength(10)); // Render Target Circle
    // Render Line of Sight
    stroke(#FF0000);
    float[] linePoint1 = cam.convert(selectedActor.dragon.posX, selectedActor.dragon.posY);
    float[] linePoint2 = cam.convert(selectedActor.posX, selectedActor.posY);
    line(linePoint1[0], linePoint1[1], linePoint2[0], linePoint2[1]);
    
    // Render Line of Attraction
    stroke(#00FF00);
    linePoint1 = cam.convert(selectedActor.getTarget()[0], selectedActor.getTarget()[1]);
    linePoint2 = cam.convert(selectedActor.posX, selectedActor.posY);
    line(linePoint1[0], linePoint1[1], linePoint2[0], linePoint2[1]);
  }
  
  textSize(20);
  fill(0, 0, 0);
  text("Population: " + actors.size(), 10, 30); 
  text("Generation: " + generationCount, 180, 30); 
  if (placeMode) text("Place Mode: " + quantityPlaceMode, 10, 60);
  if (assigningDragon) text("Assigning Dragon", 10, 90);
  if (assigningShield) text("Assigning Shield", 10, 120);
  if (assignToAll) text("Assigning to All", 10, 150);
  if (killMode) text("Kill Mode", 10, 180);
  if (runGenerationsAuto) text("Running Generations Auto", 10, height - 10);
  
  if (selectedActor != null) {
    drawInfoWindow(selectedActor, width - 150, 0, 150, 275);
  }
  
  float[] massData = new float[actors.size()];
  for (int i = 0; i < actors.size(); i++) {
    massData[i] = actors.get(i).mass;
  }
  drawHistogram(binData(massData, 20, 0, 10), width - 150, height - 75, 150, 75, #000000);
  
  float[] radiusData = new float[actors.size()];
  for (int i = 0; i < actors.size(); i++) {
    radiusData[i] = actors.get(i).radius;
  }
  drawHistogram(binData(radiusData, 20, 0, 50), width - 150, height - 150, 150, 75, #000088);
  
  float[] targetData = new float[actors.size()];
  for (int i = 0; i < actors.size(); i++) {
    targetData[i] = actors.get(i).targetDistance;
  }
  drawHistogram(binData(targetData, 50, 0, 150), width - 150, height - 225, 150, 75, #008800);
}

void update() {
  
  if (!keyPressed) {
    placeMode = false;
    assigningDragon = false;
    assigningShield = false;
    killMode = false;
    assignToAll = false;
  }
  
  
  if (mousePressed && prevMousePressed == false) {
    onMouseClick();
  }
  
  if (!mousePressed && prevMousePressed == true) {
    onMouseRelease();
  }
  
  if (mousePressed && prevMousePressed == true) {
    if (draggingSelection) {
      float[] coords = cam.project(mouseX, mouseY);
      selectedActor.posX = coords[0];
      selectedActor.posY = coords[1];
    } else {
      cam.panCamera(pmouseX - mouseX, pmouseY - mouseY);
    }
  }
  
  if (!mouseDragged && (abs(mouseX - clickPosition[0]) > CLICK_DRAG_SENSITIVITY ||
      abs(mouseY - clickPosition[1]) > CLICK_DRAG_SENSITIVITY)) {
        mouseDragged = true;
      }
  
  prevMousePressed = mousePressed;
  
  if (gamePaused) {
    // Allow user interaction and stop execution
  } else {
    float dt = deltaTime();
    for (int i = 0; i < actors.size(); i++) {
      Actor a = actors.get(i);
      if (!a.shieldAndDragonAssigned()) {
        println("Warning: Actor " + a.id + " is not assigned a dragon and shield");
        continue;
      }
      a.applyFriction(dt);
      //println("Actor Velocity Before PID: " + a.velocityX + ", " + a.velocityY);
      a.runPID(dt); 
      //println("Actor Velocity Before Collision: " + a.velocityX + ", " + a.velocityY);
      a.applyCollisionForces(dt, actors);
      //println("Actor Velocity Before Delta Calculation: " + a.velocityX + ", " + a.velocityY);
      a.calculatePosition(dt);
    }
    for (int i = 0; i < actors.size(); i++) {
      Actor a = actors.get(i);
      if (!a.positionUpdatedSinceCaluclation) {
        a.updatePosition();
        //println("Actor " + i + " is at " + a.posX + ", " + a.posY);
      }
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  cam.originZoom(cam.getZoom() * (1 + (e * ZOOM_SENSITIVITY)), mouseX, mouseY);
}

void keyPressed() {
  deltaTime();
  
  if (key == 'r') {
    actors.clear();
    gamePaused = true;
  } else if (key == 'm') {
    placeMode = true;
  } else if (key == 'd') {
    assigningDragon = true;
  } else if (key == 'k') {
    killMode = true;
  } else if (key == 'c') {
    selectedActor = null;
  } else if (key == 'b') {
    assigningShield = true;
  } else if (key == 'a') {
    assignToAll = true;
  } else if (key == 'q') {
    runGenerationsAuto = !runGenerationsAuto;
  } else if (keyCode == UP) {
    quantityPlaceMode++;
  } else if (keyCode == DOWN) {
    quantityPlaceMode--;
  } else if (key == 'p') {
    // Build a new population 
    while (actors.size() < generationSize) {
      float[] center = cam.project(width / 2, height / 2);
      Actor a = new Actor(cam, center[0] + randomGaussian() * (width / cam.zoom), center[1] + randomGaussian() * (width / cam.zoom));
      actors.add(a);
    }
    shuffleAssignments();
    generationCount++;
  } else if (key == 'g' && actors.size() >= 2) {
    // Breed a new generation
    ArrayList<Actor> parents = new ArrayList<Actor>();
    for (int i = 0; i < actors.size(); i++) {
      parents.add(actors.get(i));
    }
    while (actors.size() < generationSize) {
      // Choose parents, dont pick children of this generation
      Actor mom, dad;
      do {
        mom = getRandomActor(parents, null);
        dad = getRandomActor(parents, null);
      } while (mom == dad);
      Actor child = new Actor(cam, dad, mom);
      actors.add(child);
    }
    shuffleAssignments();
    generationCount++;
  } else if (key == 's') {
    shuffleAssignments();
  } else if (key == 'z') {
    flipAssignments();
  } else if (key == 'x') {
    // Eliminate Losers
    int startingSize = actors.size();
    int index = 0;
    for (int i = 0; i < startingSize; i++) {
      Actor a = actors.get(index);
      if (!a.isSafe()) {
        actors.remove(a);
      } else {
        index++;
      }
    }
    shuffleAssignments();
    if (!actors.contains(selectedActor)) selectedActor = null;
  } else if (key == ' ') {
    gamePaused = !gamePaused;
  }
}

void onMouseClick() {
  int[] mousePos = {mouseX, mouseY};
  clickPosition = mousePos;
  mouseDragged = false;
  if (selectedActor != null && selectedActor.isMouseHovering()) {
    draggingSelection = true;
  }
}

void onMouseRelease() {
  if (!mouseDragged) {
        // Mouse was not moved
        println("Mouse clicked in place event");
        
        // Check all actors if they are in range
        Actor foundActor = null;
        for (int i = 0; i < actors.size(); i++) {
          Actor actor = actors.get(i);
          if (actor.isMouseHovering()) {
            foundActor = actor;
            break;
          }
        }
        
        if (foundActor == null) {
          selectedActor = null;
          if (placeMode)  {
            // Make a new actor
            int numberToPlace = placeMode ? quantityPlaceMode : 1 ;
            for (int j = 0; j < numberToPlace; j++) {
              float[] actorPos;
              if (!placeMode) actorPos = cam.project(mouseX, mouseY);
              else actorPos = cam.project(mouseX + random(10) - 5, mouseY + random(10) - 5);
              Actor actor = new Actor(cam, actorPos[0], actorPos[1]);
              actors.add(actor);
              selectedActor = actor;
              
              // Assign Dragon and Shield
              if (actors.size() > 3) {
                assignRandomActors(actor);
              } else if (actors.size() == 3) {
                for (int i = 0; i < 3; i++) {
                  assignRandomActors(actors.get(i));
                }
              }
            }
          }
        } else if (killMode) {
          actors.remove(foundActor);
          mendBrokenReferences();
          if (selectedActor == foundActor) selectedActor = null;
        } else if (foundActor == selectedActor) {
          // Deselect
          selectedActor = null;
        } else {
          if (assigningDragon) {
            if (assignToAll) {
              println("Assigning Dragon to All");
              for (int i = 0; i < actors.size(); i++) {
                actors.get(i).assignDragon(foundActor);
              }
            } else if (foundActor != selectedActor) {
              selectedActor.assignDragon(foundActor);
            }
          } else if (assigningShield) {
            if (assignToAll) {
              println("Assigning Shield to All");
              for (int i = 0; i < actors.size(); i++) {
                actors.get(i).assignShield(foundActor);
              }
            } else if (foundActor != selectedActor) {
              selectedActor.assignShield(foundActor);
            }
          } else {
            selectedActor = foundActor;
            selectedActor.reportActor();
          }
        }
  } else {
      // Mouse was dragged
      println("Mouse dragged event");
  }
  
  draggingSelection = false;
}



void drawGrid() {
  int increment = height / 10;
  for (float zoomLevel = cam.getZoom(); zoomLevel <= (1 / 10.0); zoomLevel *= 10) {
    increment *= 10;
  }
  float[] box = cam.getBoundingBox();
  stroke(gridlines);
  strokeWeight(1);
  
  for(float x = 0; x < box[0] + box[2]; x += increment) {
    float[] head = cam.convert(x, box[1]);
    float[] tail = cam.convert(x, box[1] + box[3]);
    line(head[0], head[1], tail[0], tail[1]);
  }
  for(float x = 0; x > box[0]; x -= increment) {
    float[] head = cam.convert(x, box[1]);
    float[] tail = cam.convert(x, box[1] + box[3]);
    line(head[0], head[1], tail[0], tail[1]);
  }
  
  for(float y = 0; y < box[1] + box[3]; y += increment) {
    float[] head = cam.convert(box[0], y);
    float[] tail = cam.convert(box[0] + box[2], y);
    line(head[0], head[1], tail[0], tail[1]);
  }
  for(float y = 0; y > box[1]; y -= increment) {
    float[] head = cam.convert(box[0], y);
    float[] tail = cam.convert(box[0] + box[2], y);
    line(head[0], head[1], tail[0], tail[1]);
  }
}

void drawHistogram(int[] values, int x, int y, int w, int h, color c) {
  fill(#FFFFFF);
  noStroke();
  rect(x, y, w, h);
  
  // Establish Range
  int maxValue = 1;
  for (int i = 0; i < values.length; i++) {
    if (values[i] > maxValue) maxValue = values[i];
  }
  
  fill(c);
  float interval = w / (float)values.length;
  for (int i = 0; i < values.length; i++) {
    float heightRatio = values[i] / (float)maxValue;
    rect(x + (interval * i), y + (1 - heightRatio) * h, interval, heightRatio * h);
  }
  
}

public Actor getRandomActor(ArrayList<Actor> pool, ArrayList<Actor> blacklist) {
  if (blacklist != null && pool.size() <= blacklist.size()) return null;
  Actor actor;
  while (true) {
    int randIndex = floor(random(pool.size()));
    actor = pool.get(randIndex);
    boolean retry = false;
    print("Selected ID:", actor.id);
    if (blacklist != null) {
      print(" Checking ID:");
      for (int i = 0; i < blacklist.size(); i++) {
        if (blacklist.get(i) == actor) retry = true;
      }
    }
    if (retry) {
      println("Failed Retryting");
      continue;
    }
    else break;
  };
  println("Complete");
  return actor;
}

public void assignRandomActors(Actor self) {
  ArrayList<Actor> blacklist = new ArrayList<Actor>();
  blacklist.add(self);
  Actor dragon = getRandomActor(actors, blacklist);
  self.assignDragon(dragon);
  blacklist.add(dragon);
  Actor shield = getRandomActor(actors, blacklist);
  self.assignShield(shield);
}

public void mendReferences(Actor self) {
  ArrayList<Actor> blacklist = new ArrayList<Actor>();
  blacklist.add(self);
  
  Actor dragon;
  if (self.dragon == null || !actors.contains(self.dragon)) {
    dragon = getRandomActor(actors, blacklist);
    self.assignDragon(dragon);
  }
  dragon = self.dragon;
  blacklist.add(dragon);
  
  Actor shield;
  if (self.shield == null || !actors.contains(self.shield)) {
    shield = getRandomActor(actors, blacklist);
    self.assignShield(shield);
  }
}

public void shuffleAssignments() {
  for (int i = 0; i < actors.size(); i++) {
    assignRandomActors(actors.get(i));
  }
}

public void mendBrokenReferences() {
  for (int i = 0; i < actors.size(); i++) {
    Actor a = actors.get(i);
    mendReferences(a);
  }
}

int[] binData(float[] data, int bins, int min, int max) {
  int[] histogram = new int[bins];
  for (int i = 0; i < data.length; i++) {
    float d = data[i];
    int index = (d >= max) ? bins - 1 :
                (d <= min) ? 0 :
                floor(lerp(0, bins, (d - min) / (max - min)));
    histogram[index] += 1;
  }
  return histogram;
}

void drawInfoWindow(Actor actor, float x, float y, float w, float h) {
  fill(#CCCCFF);
  stroke(#777777);
  strokeWeight(2);
  rect(x, y, w, h);
  fill(#000000);
  textSize(15);
  text("ID: " + actor.id, x + 10, y + 20);
  text("Mass: " + actor.mass, x + 10, y + 40);
  text("Radius: " + actor.radius, x + 10, y + 60);
  text("Target Dist: " + actor.targetDistance, x + 10, y + 80);
  if (actor.shieldAndDragonAssigned()) text("Safe: " + actor.isSafe(), x + 10, y + 100);
}

void flipAssignments() {
  for (int i = 0; i < actors.size(); i++) {
    actors.get(i).swapReferences();
  }
}
