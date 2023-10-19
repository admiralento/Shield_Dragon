class Camera {
  float zoom = 1;
  float offsetX, offsetY = 0;
  
  public Camera() {
  }
  
  public float getZoom() {
    return zoom;
  }
  
  public void setZoom(float value) {
    if (value <= 0) {
      println("Error: Camera zoom set to", value);
      return;
    }
    zoom = value;
  }
  
  public void centerZoom(float newZoom) {
    originZoom(newZoom, width / 2, height / 2);
    //if (newZoom <= 0) {
    //  println("Error: Camera zoom set to", newZoom);
    //  return;
    //}
    //offsetX += ((width / zoom) - (width / newZoom)) / 2;
    //offsetY += ((height / zoom) - (height / newZoom)) / 2;
    //zoom = newZoom;
  }
  
  public void originZoom(float newZoom, int zoomX, int zoomY) {
    if (newZoom <= 0) {
      println("Error: Camera zoom set to", newZoom);
      return;
    }
    offsetX += ((width / zoom) - (width / newZoom)) * ((float)zoomX / width);
    offsetY += ((height / zoom) - (height / newZoom)) * ((float)zoomY / height);
    zoom = newZoom;
  }
  
  public void setOffset(float offsetX, float offsetY) {
    this.offsetX = offsetX;
    this.offsetY = offsetY;
  }
  
  public void panCamera(float x, float y) {
    this.offsetX += x / zoom;
    this.offsetY += y / zoom;
  }
  
  public float[] convert(float x, float y) {
    float[] point = {x, y};
    point[0] = (point[0] - offsetX) * zoom;
    point[1] = (point[1] - offsetY) * zoom;
    return point;
  }
  
  public float[] project(float x, float y) {
    float[] point = {x, y};
    point[0] = (point[0] / zoom) + offsetX;
    point[1] = (point[1] / zoom) + offsetY;
    return point;
  }
  
  public float scaleLength(float value) {
    return value * zoom;
  }
  
  public void reportCamera() {
    print("Camera Settings:");
    println("(Zoom: " + zoom +  ", Offset X: " + offsetX + ", Offset Y: " + offsetY + ")");
  }
  
  public float[] getBoundingBox() {
    float[] box = {offsetX, offsetY, width / zoom, height / zoom};
    return box;
  }
  
}
