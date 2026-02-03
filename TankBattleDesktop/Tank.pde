abstract class Tank {
  float x, y;
  float widthTank, heightTank;
  float vx, vy;
  float angle;
  float hp;
  float maxHp;

  // Warstwy graficzne SVG (podstawa i wieżyczka z efektami uszkodzeń)
  PShape bodyBase, bodyDamage;
  PShape turretBase, turretDamage;
  PShape imgMissile;

  float maxSpeed = 50; 
  float speed = 50; // Prędkość dynamiczna

  ArrayList<Missle> missles = new ArrayList<Missle>();

  Tank(float x, float y, float speed, float hp, PShape bodySvg, PShape gunSvg, PShape imgMissile) {
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.hp = hp;
    this.maxHp = hp;
    this.imgMissile = imgMissile;

    // Skalowanie obiektów względem rozmiaru siatki mapy
    float size = tileSize * 0.9; 
    widthTank = size;
    heightTank = size;

    // Inicjalizacja poszczególnych warstw z plików wektorowych
    bodyBase = bodySvg.getChild("base");
    bodyDamage = bodySvg.getChild("damage");
    if (bodyDamage != null) bodyDamage.setVisible(false);

    turretBase = gunSvg.getChild("base");
    turretDamage = gunSvg.getChild("damage");
    if (turretDamage != null) turretDamage.setVisible(false);
  }

  // Obsługa przemieszczania z detekcją kolizji w podziale na osie (AABB)
  void move(float dx, float dy, float deltaTime) {
    if (dx != 0 || dy != 0) {
      float len = sqrt(dx*dx + dy*dy);
      dx /= len; 
      dy /= len;
      angle = atan2(dy, dx);
    }

    vx = dx * speed;
    vy = dy * speed;

    float nextX = x + vx * deltaTime;
    float nextY = y + vy * deltaTime;
    float hitboxScale = 0.5; // Zmniejszony hitbox dla płynniejszego przejazdu

    // Weryfikacja kolizji dla osi X
    boolean tankCollisionX = collidesWithTanks(nextX, y);
    boolean mapCollisionX = collidesPlayer(nextX, y, widthTank * hitboxScale, heightTank * hitboxScale);

    if (!tankCollisionX && !mapCollisionX) {
        x = nextX;
    } else if (mapCollisionX && frameCount % 4 == 0) {
        sparks.add(new Spark(nextX, y, sparkImg)); // Efekt iskier przy tarciu o ścianę
    }

    // Weryfikacja kolizji dla osi Y
    boolean tankCollisionY = collidesWithTanks(x, nextY);
    boolean mapCollisionY = collidesPlayer(x, nextY, widthTank * hitboxScale, heightTank * hitboxScale);

    if (!tankCollisionY && !mapCollisionY) {
        y = nextY;
    } else if (mapCollisionY && frameCount % 4 == 0) {
        sparks.add(new Spark(x, nextY, sparkImg));
    }

    // Mechanika zawijania świata (Teleportacja krawędziowa) z weryfikacją drożności celu
    if (x < -widthTank/2) {
        int targetTx = cols - 1;
        int targetTy = int(y / tileSize);
        if (targetTy >= 0 && targetTy < rows && map[targetTx][targetTy] == 0) x = width + widthTank/2;
        else x = -widthTank/2;
    } 
    else if (x > width + widthTank/2) {
        int targetTx = 0;
        int targetTy = int(y / tileSize);
        if (targetTy >= 0 && targetTy < rows && map[targetTx][targetTy] == 0) x = -widthTank/2;
        else x = width + widthTank/2;
    }

    // Analogiczna logika dla osi Y
    if (y < -heightTank/2) {
        int targetTx = int(x / tileSize);
        int targetTy = rows - 1;
        if (targetTx >= 0 && targetTx < cols && map[targetTx][targetTy] == 0) y = height + heightTank/2;
        else y = -heightTank/2;
    } 
    else if (y > height + heightTank/2) {
        int targetTx = int(x / tileSize);
        int targetTy = 0;
        if (targetTx >= 0 && targetTx < cols && map[targetTx][targetTy] == 0) y = -heightTank/2;
        else y = height + heightTank/2;
    }
  }

  void shoot(float targetX, float targetY) {
    float gunAngle = atan2(targetY - y, targetX - x);
    float gunLength = widthTank/2 + widthTank/3; 
    float sx = x + cos(gunAngle) * gunLength;
    float sy = y + sin(gunAngle) * gunLength;
    missles.add(new Missle(sx, sy, gunAngle, imgMissile));
  }

  void updateMissles(float dt) {
    for (int i = missles.size()-1; i >= 0; i--) {
      Missle m = missles.get(i);
      m.update(dt);
      if (m.isOffScreen() || m.h <= 0) {
        missles.remove(i);
      }
    }
  }

  void displayMissles() {
    for (Missle m : missles) m.display();
  }

  // Detekcja kolizji między jednostkami (Circle-Circle Collision)
  boolean collidesWithTanks(float nextX, float nextY) {
    float minDistance = widthTank * 0.8;
    if (this != p && dist(nextX, nextY, p.x, p.y) < minDistance) return true;
    for (Enemy other : enemies) {
      if (this != other && dist(nextX, nextY, other.x, other.y) < minDistance) return true;
    }
    return false;
  }

  void display(float targetX, float targetY) {
    // Aktualizacja wizualna stanu pancerza
    boolean isDamaged = (hp < maxHp * 0.5);
    if (bodyDamage != null) bodyDamage.setVisible(isDamaged);
    if (turretDamage != null) turretDamage.setVisible(isDamaged);

    // Renderowanie kadłuba
    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI); 
    shape(bodyBase, -widthTank/2, -heightTank/2, widthTank, heightTank);
    shape(bodyDamage, -widthTank/2, -heightTank/2, widthTank, heightTank);
    popMatrix();

    // Renderowanie niezależnej wieżyczki skierowanej w stronę celu
    float gunAngle = atan2(targetY - y, targetX - x);
    pushMatrix();
    translate(x, y);
    rotate(gunAngle + HALF_PI);
    shape(turretBase, -widthTank/2, -heightTank/2, widthTank, heightTank);
    shape(turretDamage, -widthTank/2, -heightTank/2, widthTank, heightTank);
    popMatrix();

    // Renderowanie interfejsu HP nad jednostką
    if (hp < maxHp && hp > 0) {
      pushStyle();
      noStroke();
      rectMode(CENTER);
      fill(255, 0, 0);
      rect(x, y - heightTank/1.5, 40, 6); 
      float hpPercent = hp / maxHp;
      float greenWidth = 40 * hpPercent;
      rectMode(CORNER);
      fill(0, 255, 0);
      rect(x - 20, y - heightTank/1.5 - 3, greenWidth, 6);
      popStyle();
    }
  }

  boolean subtractHP(int amount){
    hp -= amount;
    return hp > 0;
  }

  abstract void update(float dt);
}