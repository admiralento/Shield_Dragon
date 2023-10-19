class Actor {
  int radius = 10;
  float mass = 1;
  float STROKE_WIDTH = 0.05;
  float targetDistance = 20;
  float friction = 1;
  
  float posX, posY;
  float velocityX, velocityY;
  float speedCap = 10000;
  float deltaX, deltaY;
  boolean positionUpdatedSinceCaluclation;
  
  float lastXError, lastYError;
  float propConst = 50;
  float deriConst = 1;
  float collisionRepulsion = -1000.0;
  
  int id;
  Actor shield, dragon;
  Camera camera;
  
  // Constructor
  
  public Actor(Camera camera, float spawnX, float spawnY) {
    // Generate a random Actor
    this.camera = camera;
    this.posX = spawnX;
    this.posY = spawnY;
    this.velocityX = 0.0;
    this.velocityY = 0.0;
    
    // Unique Atributes
    this.id = assignId();
    applyModestTraits();
  }
  
  public Actor(Camera camera, Actor dad, Actor mom) {
    // Generate a random Actor
    this.camera = camera;
    float distance = dist(dad.posX, dad.posY, mom.posX, mom.posY);
    this.posX = ((dad.posX + mom.posX) / 2.0) + randomGaussian() * (distance / 5);
    this.posY = ((dad.posY + mom.posY) / 2.0) + randomGaussian() * (distance / 5);
    this.velocityX = 0.0;
    this.velocityY = 0.0;
    
    // Unique Atributes
    this.id = assignId();
    applyGeneticTraits(dad, mom);
  }
  
  public void applyModestTraits() {
    do {
      this.targetDistance = randomGaussianFunction(30, 70);
    } while (this.targetDistance < 0);
    do {
      this.mass = randomGaussianFunction(2, 4);
    } while (this.mass <= 0);
    do {
      this.radius = (int)randomGaussianFunction(15, 25);
    } while (this.radius <= 0);
  }
  
  public void applyGeneticTraits(Actor dad, Actor mom) {
    // Cross Attributes
    do {
      this.mass = inherit(dad.mass, mom.mass, 0.01, 2, 4);
    } while (this.mass <= 0);
    do {
      this.radius = floor(inherit(dad.radius, mom.radius, 0.01, 10, 30));
    } while (this.radius <= 0);
    do {
      this.targetDistance = inherit(dad.targetDistance, mom.targetDistance, 0.01, this.radius * 2, this.radius * 5);
    } while (this.targetDistance <= 0);
  }
  
  private float inherit(float dadValue, float momValue, float mutationChance, float min, float max) {
    float mutation = random(1);
    if (mutation < mutationChance) return ((max - min) / 2) + (randomGaussian() * (max - min));
    else {
      if (random(1) < 0.5) return dadValue;
      else return momValue;
    }
  }
  
  private float randomGaussianFunction(float min, float max) {
    return ((max + min) / 2) + (randomGaussian() * (max - min));
  }
  
  int assignId() {
    return floor(random(2048));
  }
  
  // Methods
  
  public void applyFriction(float dt) {
    applyForce(-velocityX * mass * friction, -velocityY * mass * friction, dt);
  }
  
  public void updatePosition() {
    posX += deltaX;
    posY += deltaY;
    //println("Moved " + this.id + " " + deltaX + ", " + deltaY);
    deltaX = 0;
    deltaY = 0;
    positionUpdatedSinceCaluclation = true;
  }
  
  //public boolean updatePositionCollide(ArrayList<Actor> actors) {
  //  posX += deltaX;
  //  posY += deltaY;
  //  positionUpdatedSinceCaluclation = true;
    
  //  ArrayList<Actor> colliders = getCollidingActors(actors);
  //  for (int i = 0; i < colliders.size(); i++) {
  //    println("Collision Going to Happen");
  //    Actor c = colliders.get(i);
  //    if (!c.positionUpdatedSinceCaluclation) {
  //      if (!c.updatePositionCollide(actors)) {
  //        // Failure, Undo move
  //        posX -= deltaX;
  //        posY -= deltaY;
  //        velocityX = -2 * velocityX;
  //        velocityY = -2 * velocityY;
  //        return false;
  //      }
  //    } else {
  //      // Colliding with locked in actor
  //      // Failure, Undo move
  //      posX -= deltaX;
  //      posY -= deltaY;
  //      velocityX = -2 *velocityX;
  //      velocityY = -2 * velocityY;
  //      return false;
  //    }
  //  }
  //  return true;
  //}
  
  public void calculatePosition(float deltaTime) {
    deltaX = velocityX * deltaTime;
    deltaY = velocityY * deltaTime;
    if (Float.isNaN(deltaX)) {
      println("Nan detected in Actor " + this.id + " for deltaX");
      println("velocityX: " + velocityX + " deltaTime: " + deltaTime);
    }
    if (Float.isNaN(deltaY)) {
      println("Nan detected in Actor " + this.id + " for deltaY");
      println("velocityY: " + velocityY + " deltaTime: " + deltaTime);
    }
    positionUpdatedSinceCaluclation = false;
  }
  
  public void applyForce(float forceX, float forceY, float deltaTime) {

    //println("Applying Force: " + forceX + ", " + forceY + " for " + deltaTime);
    
    // Don't calculate bad forces
    if (Float.isNaN(forceX) || Float.isNaN(forceY)) {
      println("Warning: NaN forces on Actor #" + this.id);
      return;
    }
    
    if (Float.isInfinite(forceX) || Float.isInfinite(forceY)) {
      // If the forces are infinite, simply max out speed in the direction of travel
      float[] newVelocity = scaleVector(velocityX, velocityY, speedCap);
      velocityX = newVelocity[0];
      velocityY = newVelocity[1];
      println("Warning: Infinte forces on Actor #" + this.id);
      return;
    }
    
    // Calculate the resultant Acceleration
    float dvx = (forceX / mass) * deltaTime;
    float dvy = (forceY / mass) * deltaTime;
    
    if (Float.isNaN(dvx) || Float.isNaN(dvy)) {
      println("Warning: Error in actor #" + this.id + " while applying force. Is the mass set to zero?");
      return;
    }
    
    // Check the magnitude of the final speed
    float nextVX = velocityX + dvx;
    float nextVY = velocityY + dvy;
    float magnitude = mag(nextVX, nextVY);
    
    if (Float.isInfinite(magnitude)) {
      // If calculated velocity is infinte
      if (Float.isInfinite(nextVX) || Float.isInfinite(nextVY)) {
        // Cap it out in direction of travel previous
        float[] newVelocity = scaleVector(velocityX, velocityY, speedCap);
        velocityX = newVelocity[0];
        velocityY = newVelocity[1];
      } else {
        // Cap it out in direction of the force previous
        float[] newVelocity = scaleVector(dvx, dvy, speedCap);
        velocityX = newVelocity[0];
        velocityY = newVelocity[1];
      }
      println("Warning: Accelartion Error on Actor #" + this.id);
      return;
    }
    
    if (magnitude > speedCap) {
      float[] newVelocity = scaleVector(nextVX, nextVY, speedCap);
      velocityX = newVelocity[0];
      velocityY = newVelocity[1];
    } else {
      velocityX = nextVX;
      velocityY = nextVY;
    }
  }
  
  private float[] scaleVector(float x, float y, float mag) {
    float[] vector = {0, 0};
    float currentMag = mag(x,y);
    if (currentMag == 0) return vector;
    
    if (Float.isInfinite(currentMag)) {
      println("Error in scaleVector, magnitude is infinite", x, y, mag);
    }
    vector[0] = ( x / currentMag ) * mag;
    vector[1] = ( y / currentMag ) * mag;
    if (Float.isNaN(vector[0])) {
      println("Error in scaleVector, x comp is NaN", x, y, mag);
    }
    if (Float.isNaN(vector[1])) {
      println("Error in scaleVector, y comp is NaN", x, y, mag);
    }
    return vector;
  }
      
  public void runPID(float dt) {
    float[] target = getTarget();
    float errorX = target[0] - posX;
    float errorY = target[1] - posY;
    
    float forceProportionalX = errorX * propConst;
    float forceProportionalY = errorY * propConst;
    
    float forceDerivativeX = ((errorX - lastXError) / dt) * deriConst;
    float forceDerivativeY = ((errorY - lastYError) / dt) * deriConst;
    
    lastXError = errorX;
    lastYError = errorY;
    
    applyForce(forceProportionalX + forceDerivativeX, forceProportionalY + forceDerivativeY, dt);
  }
  
  public void applyCollisionForces(float dt, ArrayList<Actor> actors) {
    ArrayList<Actor> colliders = getCollidingActors(actors);
    for (int i = 0; i < colliders.size(); i++) {
      Actor c = colliders.get(i);
      
      float distX = c.posX - posX;
      float distY = c.posY - posY;
      float overlap = radius + c.radius - mag(distX, distY);
      float repulsionMag = collisionRepulsion * overlap;
      float angle = atan2(distY, distX);
      
      float collisionForceX = repulsionMag * cos(angle);
      float collisionForceY = repulsionMag * sin(angle);
      
      applyForce(collisionForceX, collisionForceY, dt);
    }
  }
  
  public float[] getTarget() {
    float[] unitVector = scaleVector(shield.posX - dragon.posX, shield.posY - dragon.posY, 1);
    float targetX = shield.posX + unitVector[0] * (targetDistance + shield.radius + this.radius);
    float targetY = shield.posY + unitVector[1] * (targetDistance + shield.radius + this.radius);
    float[] target = {targetX, targetY};
    return target;
  }
  
  public void assignShield(Actor newReference) {
    this.shield = newReference;
    if (newReference != null) println("Assigning", newReference.id, "as Shield for", id);
  }
  
  public Actor getShield() {
    return this.shield;
  };
  
  public void assignDragon(Actor newReference) {
    this.dragon = newReference;
    if (newReference != null) println("Assigning", newReference.id, "as Dragon for", id);
  }
  
  public Actor getDragon() {
    return this.dragon;
  };
  
  public void swapReferences() {
    Actor temp = dragon;
    dragon = shield;
    shield = temp;
  }
  
  public boolean shieldAndDragonAssigned() {
    return this.dragon != null && this.shield != null;
  }
  
  public void drawActor(color c) {
    float[] center = camera.convert(posX, posY);
    fill(c);  // Fill with passed color
    stroke(c);
    strokeWeight(max(1, camera.scaleLength(radius * STROKE_WIDTH))); // Scale Border Width
    circle(center[0], center[1], camera.scaleLength(radius * 2)); // Render Circle
    
    // Lighten up circle
    if (isMouseHovering()) {
      fill(255,255,255,30);
      stroke(0,0,0);
      circle(center[0], center[1], camera.scaleLength(radius * 2)); // Render Circle
    }
  }
  
  public void reportActor() {
    println("Selected ID:", id);
    if (dragon != null) println("Dragon ID:", dragon.id);
    else println("Dragon ID:", null);
    if (shield != null) println("Shield ID:", shield.id);
    else println("Shield ID:", null);
    println("Mass:", mass);
    println("Radius:", radius);
    println("Target Distance:", targetDistance);
  }
  
  public ArrayList<Actor> getCollidingActors(ArrayList<Actor> actors) {
    ArrayList<Actor> colliders = new ArrayList<Actor>();
    for (int i = 0; i < actors.size(); i++) {
      Actor a = actors.get(i);
      if (a != this && mag(a.posX - this.posX, a.posY - this.posY) < (this.radius + a.radius)) {
        colliders.add(a);
      }
    }
    return colliders;
  }
  
  private float distanceToLine(float slope, float yIntercept, float px, float py) {
    return abs((slope * px) + (-1.0 * py) + yIntercept) / mag(slope, -1);
  }
  
  public float shieldDistanceToLineOfSight() {
    float slope = (posY - dragon.posY) / (posX - dragon.posX);
    float yIntercept = posY - slope * posX;
    return distanceToLine(slope, yIntercept, shield.posX, shield.posY);
  }
  
  public boolean isSafe() {
    return (shieldDistanceToLineOfSight() <= shield.radius) &&
           dist(dragon.posX, dragon.posY, posX, posY) > dist(posX, posY, shield.posX, shield.posY);
  }
  
  public boolean isMouseHovering() {
    float[] mousePos = camera.project(mouseX, mouseY);
    return mag(posX - mousePos[0], posY - mousePos[1]) < radius;
  }
  
}
