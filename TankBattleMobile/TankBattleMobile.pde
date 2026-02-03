// ============================================================
// ZASOBY I ZMIENNE GLOBALNE (ANDROID)
// ============================================================
// --- Dźwięki ------------------------------------------------
float shakeAmount = 0;

// --- Sterowanie dotykowe ------------------------------------
float joyX, joyY;
float joyRadius = 200;
float thumbRadius = 60;
float shootButtonX, shootButtonY;
boolean isShooting = false;
float pauseBtnSize = 80;
float pauseBtnMargin = 30;

// Tablice do śledzenia dotknięć
float[] touchX = new float[5];
float[] touchY = new float[5];
boolean[] touchActive = new boolean[5];
int joyTouchId = -1;
int shootTouchId = -1;

// --- Stan gry -----------------------------------------------
Player p;
float lastTime = 0;
ArrayList<Enemy> enemies;
int numberOfEnemies;
float playerGunAngle = 0;
enum GameStatus {
  MENU, PLAY, GAMEOVER, WIN, PAUSE, TUTORIAL
}

GameStatus gameState = GameStatus.MENU;
GameStatus previousState = GameStatus.MENU;

// --- Tutorial -----------------------------------------------
int tutorialStep = 0; 
int initialWallCount = 0;

// --- Efekty wizualne ----------------------------------------
ArrayList<Explosion> explosions = new ArrayList<Explosion>();
ArrayList<Spark> sparks = new ArrayList<Spark>();

// --- System powiadomień -------------------------------------
String notificationText = "";
int notificationTime = -5000;
int displayDuration = 2000;

// --- Struktura mapy -----------------------------------------
int desiredCols = 25;
float tileSize;
int cols, rows;
int[][] map;
float[][] tileHP;
float maxTileHP = 100;

// ============================================================
// FUNKCJE RYSOWANIA KSZTAŁTÓW
// ============================================================

void drawMissilePlayer(float x, float y, float w, float h, float angle) {
    float s = 0.7;
    float sw = w * s;
    float sh = h * s;

    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);
    strokeJoin(ROUND);

    // 1. Płomień
    noStroke();
    fill(255, 69, 0); 
    triangle(-sw/4, sh/2, sw/4, sh/2, 0, sh*0.9);
    fill(255, 215, 0); 
    triangle(-sw/8, sh/2, sw/8, sh/2, 0, sh*0.75);

    // 2. Silnik / Dysza
    stroke(0);
    fill(28, 28, 28);
    rect(0, sh/2.5, sw/2, sh/6);

    // 3. Korpus
    fill(85, 107, 47); 
    rect(0, 0, sw/1.5, sh/1.5);

    // 4. Głowica
    fill(218, 165, 32); 
    triangle(-sw/3, -sh/3, sw/3, -sh/3, 0, -sh/1.5);
    
    popMatrix();
}

void drawMissileEnemy(float x, float y, float w, float h, float angle) {
    float s = 0.7;
    float sw = w * s;
    float sh = h * s;

    pushMatrix();
    translate(x, y);
    rotate(angle+HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);
    strokeJoin(ROUND);

    // 1. Płomień
    noStroke();
    fill(255, 69, 0);
    triangle(-sw/4, sh/2, sw/4, sh/2, 0, sh*0.9);
    fill(255, 215, 0);
    triangle(-sw/8, sh/2, sw/8, sh/2, 0, sh*0.75);

    // 2. Silnik
    stroke(0);
    fill(51, 51, 51);
    rect(0, sh/2.5, sw/2, sh/6);

    // 3. Korpus 
    fill(136, 136, 136);
    rect(0, 0, sw/1.5, sh/1.5);

    // 4. Głowica
    fill(204, 0, 0);
    triangle(-sw/3, -sh/3, sw/3, -sh/3, 0, -sh/1.5);
    
    popMatrix();
}

void drawTankPlayerBottom(float x, float y, float w, float h, float angle, float dmg) {
    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // 1. Gąsienice
    fill(96, 96, 96);
    rect(-w/2.5, 0, w/4, h, 2);
    rect(w/2.5, 0, w/4, h, 2);

    // Prążki na gąsienicach
    strokeWeight(1.5);
    for (float i = -h/2 + 5; i < h/2; i += 10) {
        line(-w/2.5 - w/8, i, -w/2.5 + w/8, i);
        line(w/2.5 - w/8, i, w/2.5 + w/8, i);
    }

    // 2. Korpus
    strokeWeight(2);
    fill(85, 107, 47);
    rect(0, 0, w/1.8, h * 0.8);

    // 3. Detale z tyłu
    noFill();
    rect(-w/6, h/3, w/10, h/10);
    rect(0, h/3, w/10, h/10);
    rect(w/6, h/3, w/10, h/10);

    // 4. Efekty uszkodzeń
    if (dmg < 0.5) {
        noStroke();
        // Kłęby dymu
        fill(17, 17, 17, 180); ellipse(0, h/4, w/2, w/2);
        fill(51, 51, 51, 150); ellipse(w/4, h/5, w/2.5, w/2.5);
        fill(34, 34, 34, 130); ellipse(-w/4, h/5, w/3, w/3);
        
        // Płomień
        fill(255, 69, 0);
        beginShape();
        vertex(-w/4, h/2.5); vertex(-w/6, h/1.2); vertex(0, h/2.5);
        vertex(w/8, h/1.3); vertex(w/4, h/2.5);
        endShape(CLOSE);
        
        fill(255, 215, 0);
        triangle(-w/8, h/2.5, 0, h/1.5, w/8, h/2.5);
    }

    popMatrix();
}

void drawTankPlayerGun(float x, float y, float w, float h, float angle, float dmg) {
    float s = 0.8;
    float sw = w * s;
    float sh = h * s;

    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);

    // 1. Lufa
    fill(62, 76, 36);
    rect(0, -sh/2, sw/8, sh);
    rect(0, -sh, sw/5, sh/5);

    // 2. Wieżyczka
    fill(107, 142, 35);
    beginShape();
    vertex(-sw/4, sh/4);
    vertex(-sw/4, -sh/8);
    vertex(-sw/8, -sh/3);
    vertex(sw/8, -sh/3);
    vertex(sw/4, -sh/8);
    vertex(sw/4, sh/4);
    vertex(0, sh/2.5);
    endShape(CLOSE);

    // 3. Włazy
    fill(72, 96, 24);
    rect(-sw/8, 0, sw/12, sh/8);
    rect(sw/8, 0, sw/10, sh/6);

    // 4. Uszkodzenia wieżyczki
    if (dmg < 0.4) {
        stroke(0, 180);
        line(-sw/6, -sh/10, 0, 0); 
        line(0, 0, sw/8, -sh/20);
        
        noStroke();
        fill(0, 80);
        ellipse(sw/6, 0, sw/5, sw/5);
    }

    popMatrix();
}

void drawTankEnemyBottom(float x, float y, float w, float h, float angle, float dmg) {
    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // 1. Gąsienice
    fill(96, 96, 96);
    rect(-w/2.5, 0, w/4, h, 2);
    rect(w/2.5, 0, w/4, h, 2);

    // Detale gąsienic
    strokeWeight(1);
    for (float i = -h/2 + 5; i < h/2; i += 10) {
        line(-w/2.5 - w/8, i, -w/2.5 + w/8, i);
        line(w/2.5 - w/8, i, w/2.5 + w/8, i);
    }

    // 2. Korpus
    strokeWeight(2);
    fill(179, 0, 0);
    rect(0, 0, w/1.8, h * 0.8);

    // 3. Detale z tyłu
    noFill();
    rect(-w/6, h/3, w/10, h/10);
    rect(0, h/3, w/10, h/10);
    rect(w/6, h/3, w/10, h/10);

    // 4. Efekty uszkodzeń
    if (dmg < 0.5) {
        noStroke();
        // Ciemny dym
        fill(34, 34, 34, 150);
        ellipse(0, 0, w/2, w/2);
        ellipse(w/4, -h/6, w/3, w/3);
        
        // Ogień z tyłu
        fill(255, 69, 0);
        beginShape();
        vertex(-w/4, h/2.5); vertex(-w/6, h/1.2); vertex(0, h/2.5);
        vertex(w/8, h/1.3); vertex(w/4, h/2.5);
        endShape(CLOSE);
        
        fill(255, 215, 0);
        triangle(-w/8, h/2.5, 0, h/1.5, w/8, h/2.5);
    }

    popMatrix();
}

void drawTankEnemyGun(float x, float y, float w, float h, float angle, float dmg) {
    float s = 0.8;
    float sw = w * s;
    float sh = h * s;

    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);

    // 1. Lufa
    fill(204, 0, 0);
    rect(0, -sh/2, sw/8, sh);
    rect(0, -sh, sw/5, sh/5);

    // 2. Wieżyczka
    fill(255, 26, 26);
    beginShape();
    vertex(-sw/4, sh/4);
    vertex(-sw/4, -sh/8);
    vertex(-sw/8, -sh/3);
    vertex(sw/8, -sh/3);
    vertex(sw/4, -sh/8);
    vertex(sw/4, sh/4);
    vertex(0, sh/2.5);
    endShape(CLOSE);

    // 3. Włazy/Detale
    fill(230, 0, 0);
    rect(-sw/8, 0, sw/12, sh/8);
    rect(sw/8, 0, sw/10, sh/6);

    // 4. Uszkodzenia wieżyczka
    if (dmg < 0.4) {
        stroke(0);
        line(-sw/6, -sh/6, 0, 0);
        line(0, 0, sw/6, -sh/10);
        noStroke();
        fill(0, 100);
        ellipse(sw/8, sh/8, sw/4, sw/4);
    }

    popMatrix();
}

void drawExplosion(float x, float y, float size) {
    pushMatrix();
    translate(x, y);
    
    // Centralna kula ognia
    for (int i = 0; i < 5; i++) {
        float r = size * 0.8 * (1 - i * 0.15);
        int alpha = 255 - i * 50;
        fill(255, 165 - i * 20, 0, alpha);
        noStroke();
        ellipse(0, 0, r, r);
    }
    
    // Iskry
    for (int i = 0; i < 12; i++) {
        float a = random(TWO_PI);
        float d = random(size * 0.3, size * 0.8);
        float sparkX = cos(a) * d;
        float sparkY = sin(a) * d;
        float sparkSize = random(3, 8);
        
        fill(255, (int)random(200, 255), 0);
        ellipse(sparkX, sparkY, sparkSize, sparkSize);
    }
    
    popMatrix();
}

void drawSparks(float x, float y, float size) {
    pushMatrix();
    translate(x, y);
    
    // Kilka małych żółtych kółek
    for (int i = 0; i < 4; i++) {
        float offsetX = random(-size/2, size/2);
        float offsetY = random(-size/2, size/2);
        float sparkSize = random(2, 6);
        
        fill(255, 255, 0, random(150, 255));
        noStroke();
        ellipse(offsetX, offsetY, sparkSize, sparkSize);
    }
    
    popMatrix();
}

void drawTileGround(float x, float y, float size) {
    pushMatrix();
    translate(x, y);
    noStroke();
    
    // Tło (piaskowy/skalisty)
    fill(139, 139, 122);
    rect(0, 0, size, size);
    
    // Plamy terenu
    fill(95, 95, 80, 150);
    ellipse(size * 0.25, size * 0.2, size * 0.3, size * 0.2);
    ellipse(size * 0.75, size * 0.75, size * 0.3, size * 0.2);
    
    // Małe kamienie
    fill(62, 62, 54);
    ellipse(size * 0.8, size * 0.2, size * 0.06, size * 0.06);
    ellipse(size * 0.2, size * 0.8, size * 0.04, size * 0.04);
    
    // Delikatne rysy/linie
    stroke(74, 74, 64, 80);
    strokeWeight(1);
    line(0, size * 0.1, size * 0.2, 0);
    line(size * 0.8, size, size, size * 0.9);
    popMatrix();
}

void drawTileBox(float x, float y, float size, float hp) {
    pushMatrix();
    translate(x, y);
    rectMode(CORNER);
    strokeJoin(ROUND);

    if (hp > 75) {
        // --- STAN: IDEALNY ---
        fill(77, 89, 102);
        stroke(0);
        strokeWeight(size * 0.04);
        rect(2, 2, size - 4, size - 4);
        
        // Przekątne (X)
        stroke(0, 200); 
        line(size * 0.1, size * 0.1, size * 0.9, size * 0.9);
        line(size * 0.9, size * 0.1, size * 0.1, size * 0.9);
        
        // Nity w rogach
        noStroke();
        fill(47, 79, 79);
        ellipse(size * 0.1, size * 0.1, size * 0.07, size * 0.07);
        ellipse(size * 0.9, size * 0.1, size * 0.07, size * 0.07);
        ellipse(size * 0.1, size * 0.9, size * 0.07, size * 0.07);
        ellipse(size * 0.9, size * 0.9, size * 0.07, size * 0.07);

    } else if (hp > 40) {
        // --- STAN: LEKKO USZKODZONY ---
        fill(77, 89, 102);
        stroke(0);
        strokeWeight(2);
        quad(4, 4, size-4, 6, size-6, size-6, 6, size-4);
        
        // Pęknięcia
        stroke(0, 150);
        line(size*0.3, size*0.4, size*0.2, size*0.3);
        line(size*0.3, size*0.4, size*0.4, size*0.35);
        
        // Odpadający nit
        fill(26, 26, 26);
        ellipse(size * 0.2, size * 0.2, size * 0.06, size * 0.06);

    } else if (hp > 0) {
        // --- STAN: MOCNO USZKODZONY ---
        fill(54, 61, 69);
        stroke(0);
        strokeWeight(2);
        beginShape();
        vertex(size*0.12, size*0.15);
        vertex(size*0.88, size*0.08);
        vertex(size*0.92, size*0.45);
        vertex(size*0.8, size*0.88);
        vertex(size*0.45, size*0.92);
        vertex(size*0.08, size*0.82);
        endShape(CLOSE);
        
        // Dziura w środku
        fill(26, 26, 26);
        ellipse(size*0.5, size*0.5, size*0.2, size*0.2);

    } else {
        // --- STAN: ZNISZCZONY ---
        noStroke();
        fill(43, 36, 31);
        ellipse(size*0.5, size*0.55, size*0.9, size*0.7);
        fill(59, 50, 44);
        ellipse(size*0.48, size*0.52, size*0.8, size*0.6);
    }
    
    popMatrix();
}

// ============================================================
// ABSTRAKCYJNA KLASA TANK
// ============================================================

abstract class Tank {
  float x, y;
  float widthTank, heightTank;
  float vx, vy;
  float angle;
  float hp;
  float maxHp;
  
  int tankType; // 0 = gracz, 1 = wróg
  float maxSpeed = 50; 
  float speed = 50;
  
  ArrayList<Missle> missles = new ArrayList<Missle>();

  Tank(float x, float y, float speed, float hp, int tankType) {
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.hp = hp;
    this.maxHp = hp;
    this.tankType = tankType;

    float size = tileSize * 0.9; 
    widthTank = size;
    heightTank = size;
  }
  
  float getHealthRatio() {
      return hp / maxHp; 
    }

  void move(float dx, float dy, float deltaTime) {
    // TYLKO dla gracza: aktualizuj kąt tylko gdy faktycznie się rusza
    if (tankType == 0) {  // gracz
      if (dx != 0 || dy != 0) {
        float len = sqrt(dx*dx + dy*dy);
        dx /= len;
        dy /= len;
        angle = atan2(dy, dx);
      }
      // jeśli dx == 0 && dy == 0, angle pozostaje bez zmian!
    } else {  // wrogowie
      if (dx != 0 || dy != 0) {
        float len = sqrt(dx*dx + dy*dy);
        dx /= len;
        dy /= len;
        angle = atan2(dy, dx);
      }
    }

    vx = dx * speed;
    vy = dy * speed;

    float nextX = x + vx * deltaTime;
    float nextY = y + vy * deltaTime;
    float hitboxScale = 0.5;

    boolean tankCollisionX = collidesWithTanks(nextX, y);
    boolean mapCollisionX = collidesPlayer(nextX, y, widthTank * hitboxScale, heightTank * hitboxScale);

    if (!tankCollisionX && !mapCollisionX) {
      x = nextX;
    } else if (mapCollisionX && frameCount % 4 == 0) {
      sparks.add(new Spark(nextX, y));
    }

    boolean tankCollisionY = collidesWithTanks(x, nextY);
    boolean mapCollisionY = collidesPlayer(x, nextY, widthTank * hitboxScale, heightTank * hitboxScale);

    if (!tankCollisionY && !mapCollisionY) {
      y = nextY;
    } else if (mapCollisionY && frameCount % 4 == 0) {
      sparks.add(new Spark(x, nextY));
    }

    // Teleportacja krawędziowa
    if (x < -widthTank/2) {
      int targetTx = cols - 1;
      int targetTy = int(y / tileSize);
      if (targetTy >= 0 && targetTy < rows && map[targetTx][targetTy] == 0) x = width + widthTank/2;
      else x = -widthTank/2;
    } else if (x > width + widthTank/2) {
      int targetTx = 0;
      int targetTy = int(y / tileSize);
      if (targetTy >= 0 && targetTy < rows && map[targetTx][targetTy] == 0) x = -widthTank/2;
      else x = width + widthTank/2;
    }

    if (y < -heightTank/2) {
      int targetTx = int(x / tileSize);
      int targetTy = rows - 1;
      if (targetTx >= 0 && targetTx < cols && map[targetTx][targetTy] == 0) y = height + heightTank/2;
      else y = -heightTank/2;
    } else if (y > height + heightTank/2) {
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
    missles.add(new Missle(sx, sy, gunAngle, tankType));
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

  boolean collidesWithTanks(float nextX, float nextY) {
    float minDistance = widthTank * 0.8;
    if (this != p && dist(nextX, nextY, p.x, p.y) < minDistance) return true;
    for (Enemy other : enemies) {
      if (this != other && dist(nextX, nextY, other.x, other.y) < minDistance) return true;
    }
    return false;
  }

  void display(float targetX, float targetY) {
    float dmg = getHealthRatio();
    // Renderowanie kadłuba
    if (tankType == 0) {
      drawTankPlayerBottom(x, y, widthTank, heightTank, angle, dmg);
    } else {
      drawTankEnemyBottom(x, y, widthTank, heightTank, angle, dmg);
    }

    // Renderowanie wieżyczki
    float gunAngle = atan2(targetY - y, targetX - x);
    if (tankType == 0) {
      drawTankPlayerGun(x, y, widthTank, heightTank, gunAngle, dmg);
    } else {
      drawTankEnemyGun(x, y, widthTank, heightTank, gunAngle, dmg);
    }

    // Renderowanie interfejsu HP
    if (hp < maxHp && hp > 0) {
      pushStyle();
      noStroke();
      rectMode(CENTER);
      fill(255, 0, 0);
      rect(x, y - heightTank/1.5, 60, 8); 
      float hpPercent = hp / maxHp;
      float greenWidth = 60 * hpPercent;
      rectMode(CORNER);
      fill(0, 255, 0);
      rect(x - 30, y - heightTank/1.5 - 4, greenWidth, 8);
      popStyle();
    }
  }

  boolean subtractHP(int amount) {
    hp -= amount;
    return hp > 0;
  }

  abstract void update(float dt);
}

// ============================================================
// KLASA PLAYER
// ============================================================

class Player extends Tank {
  float shootCooldown = 0;
  float shootInterval = 0.2;
  Player() {
    super(width/2, height/2, 200, 500, 0);
    maxSpeed = 200;
  }

  void update(float dt) {
    if (shootCooldown > 0) shootCooldown -= dt;
    if (hp < maxHp * 0.5) {
      speed = maxSpeed * 0.7;
    } else {
      speed = maxSpeed;
    }
  }
}

// ============================================================
// KLASA ENEMY
// ============================================================

enum State { WANDER, CHASE }

class Enemy extends Tank {
  float dirX, dirY;
  float changeTimer = 0;
  float shootCooldown = 0;
  float shootInterval = 1.5;
  State state = State.WANDER;
  float viewDistance = tileSize * 6;

  Enemy() {
    super(0, 0, 50, 100, 1);
    float minDist = tileSize * 6;

    // Losowanie pozycji startowej
    do {
      x = random(width);
      y = random(height);
    } while (
      !canSpawnTank(x, y, widthTank, heightTank) ||
      dist(x, y, p.x, p.y) < minDist
    );
  }

  void update(float dt) {
    changeTimer -= dt;
    shootCooldown -= dt;

    float dx = 0;
    float dy = 0;
    float distToPlayer = dist(x, y, p.x, p.y);
    
    // Algorytm przełączania stanów
    if (distToPlayer < viewDistance) {
      state = State.CHASE;
    } else {
      state = State.WANDER;
    }

    // Skalowanie prędkości
    if (hp < maxHp * 0.5) {
      speed = maxSpeed * 0.7;
    } else {
      speed = maxSpeed;
    }

    // Logika zachowania AI
    if (state == State.CHASE) {
      dx = p.x - x;
      dy = p.y - y;

      float len = sqrt(dx*dx + dy*dy);
      if (len > 0) {
        dx /= len;
        dy /= len;
      }

      // Automatyczny ostrzał
      if (shootCooldown <= 0) {
        shoot(p.x, p.y);
        shootCooldown = shootInterval;
      }
    } else { // WANDER
      if (changeTimer <= 0) {
        float a = random(TWO_PI);
        dx = cos(a);
        dy = sin(a);
        changeTimer = 1.5;
      } else {
        dx = vx / speed;
        dy = vy / speed;
      }
    }
    
    move(dx, dy, dt);
  }
}

// ============================================================
// KLASA MISSLE
// ============================================================

class Missle {
  float x, y;
  float angle;
  float speed;
  int missileType; // 0 = gracz, 1 = wróg
  float w, h;

  Missle(float x, float y, float angle, int missileType) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.missileType = missileType;
    speed = tileSize * 5;
    w = tileSize * 0.6;
    h = w * 1.4;
  }

  void update(float deltaTime) {
    float nextX = x + cos(angle) * speed * deltaTime; 
    float nextY = y + sin(angle) * speed * deltaTime; 

    // Sprawdzenie kolizji
    if (collidesPoint(nextX, nextY)) {
      applyTileDamage(nextX, nextY);
      w = 0; h = 0;
      return;
    }

    x = nextX; 
    y = nextY;

    // Teleportacja przez krawędzie
    boolean teleported = false;
    if (x < 0) { x = width; teleported = true; }
    else if (x > width) { x = 0; teleported = true; }
    
    if (y < 0) { y = height; teleported = true; }
    else if (y > height) { y = 0; teleported = true; }

    // Sprawdzenie kolizji po teleportacji
    if (teleported && collidesPoint(x, y)) {
      applyTileDamage(x, y);
      w = 0; h = 0;
    }
  }

  void applyTileDamage(float checkX, float checkY) {
    int tx = int(checkX / tileSize); 
    int ty = int(checkY / tileSize);
    
    if (tx >= 0 && tx < cols && ty >= 0 && ty < rows) { 
      if (map[tx][ty] == 1) {
        tileHP[tx][ty] -= 3;
        explosions.add(new Explosion(checkX, checkY));
        if (tileHP[tx][ty] <= 0) {
          map[tx][ty] = 0;
        }
      }
    }
  }

  void display() {
    if (missileType == 0) {
      drawMissilePlayer(x, y, w, h, angle);
    } else {
      drawMissileEnemy(x, y, w, h, angle);
    }
  }

  boolean isOffScreen() {
    return x < -100 || x > width + 100 || y < -100 || y > height + 100;
  }
}

// ============================================================
// KLASA EXPLOSION
// ============================================================

class Explosion {
  float x, y;
  float timer = 0;
  float size;
  boolean alive = true;

  Explosion(float x, float y) {
    this.x = x;
    this.y = y;
    this.size = tileSize * 1.0;
  }

  void update(float dt) {
    timer += dt;
    if (timer > 0.7) alive = false;
  }

  void display() {
    if (!alive) return;
    pushMatrix(); 
    drawExplosion(x, y, size * (0.5 + timer * 0.7));
    popMatrix();
  }
}

// ============================================================
// KLASA SPARK
// ============================================================

class Spark {
  float x, y, vx, vy;
  float timer = 0;
  boolean alive = true;
  float size;

  Spark(float x, float y) {
    this.x = x;
    this.y = y;
    this.size = tileSize * 0.30; 
    this.vx = random(-tileSize * 2, tileSize * 2); 
    this.vy = random(-tileSize * 2, tileSize * 2);
  }

  void update(float dt) {
    x += vx * dt;
    y += vy * dt;
    timer += dt;
    if (timer > 0.35) alive = false; 
  }

  void display() {
    if (!alive) return;
    drawSparks(x, y, size);
  }
}

// ============================================================
// INICJALIZACJA (ANDROID)
// ============================================================

void setup() {
  fullScreen();
  orientation(LANDSCAPE);
  
  // Inicjalizacja dżojstika
  joyX = width * 0.15;
  joyY = height * 0.75;
  shootButtonX = width * 0.85;
  shootButtonY = height * 0.75;
  
  // Inicjalizacja tablic dotknięć
  for (int i = 0; i < 5; i++) {
    touchActive[i] = false;
  }

  
  calculateTilesize(desiredCols);
  
  // Utworzenie gracza
  p = new Player();
  
  numberOfEnemies = int(desiredCols * 0.15);
  enemies = new ArrayList<Enemy>();
  
  generateMap();
  
  gameState = GameStatus.MENU;
  
  // Większe teksty na mobilne
  textSize(32);
}

void calculateTilesize(int desiredCols) {
  tileSize = width / (float)desiredCols;
  cols = desiredCols;
  rows = ceil(height / tileSize);
  tileHP = new float[cols][rows];
}

// ============================================================
// GŁÓWNA PĘTLA GRY
// ============================================================

void draw() {
  resetMatrix();
  if (gameState == GameStatus.MENU) {
    drawMenu();
    checkMenuTouch();
    return;
  }
  
  // RYSOWANIE WIZUALIÓW (mapa, czołgi, efekty)
  if (gameState == GameStatus.TUTORIAL) {
    updateTutorialLogic();
    drawTutorialGame(); // Ta funkcja już wywołuje drawGameVisuals()
  } else {
    drawGameVisuals();
  }
  
  // LOGIKA DLA STANU PLAY
  if (gameState == GameStatus.PLAY) {
    float currentTime = millis() / 1000.0;
    float deltaTime = currentTime - lastTime;
    lastTime = currentTime;
    
    if (deltaTime > 0.1) deltaTime = 0.016;
    
    updateGameLogic(deltaTime);
    checkWinLose();
    
  } else if (gameState == GameStatus.GAMEOVER) {
    gameOver();
    updateTouchPositions();
    checkEndScreenTouch();
  } else if (gameState == GameStatus.WIN) {
    Win();
    updateTouchPositions();
    checkEndScreenTouch();
  } else if (gameState == GameStatus.PAUSE) {
    drawPauseMenu();
    checkPauseTouch();
  }
  
  // KLUCZOWA ZMIANA: Rysuj kontrolki, jeśli jesteś w grze LUB w tutorialu
  // Ten blok musi być POZA instrukcjami 'if...return' menu
  if (gameState == GameStatus.PLAY || gameState == GameStatus.TUTORIAL) {
    updateTouchPositions();
    drawJoystick();
    drawShootButton();
    checkGameTouch();
    drawPauseButton();
  }
  
  drawNotification();
}

// ============================================================
// FUNKCJE OBSŁUGI DOTYKU (ANDROID)
// ============================================================

void updateTouchPositions() {
  // Aktualizuj pozycje aktywnych dotknięć
  for (int i = 0; i < touches.length; i++) {
    if (touches[i] != null) {
      touchX[i] = touches[i].x;
      touchY[i] = touches[i].y;
      touchActive[i] = true;
    } else {
      touchActive[i] = false;
    }
  }
}

void checkGameTouch() {
  // POPRAWKA: zawsze sprawdzaj czy touches istnieje i ma elementy
  if (touches == null) return;
  
  // Sprawdź czy któreś dotknięcie jest w obszarze dżojstika
  boolean foundJoyTouch = false;
  boolean foundShootTouch = false;
  
  for (int i = 0; i < touches.length; i++) {
    if (touches[i] != null) {
      float tx = touches[i].x;
      float ty = touches[i].y;
      
   // 1. Sprawdź pauzę
      if (tx > pauseBtnMargin && tx < pauseBtnMargin + pauseBtnSize && 
          ty > pauseBtnMargin && ty < pauseBtnMargin + pauseBtnSize) {
          previousState = gameState;
          gameState = GameStatus.PAUSE;
          return;
      }
      
      // 2. Sprawdź przycisk strzału (Prawa strona)
      if (tx > width * 0.5 && dist(tx, ty, shootButtonX, shootButtonY) < 150) { 
        foundShootTouch = true;
        shootTouchId = i;
        
        if (p.shootCooldown <= 0) {
          // STRZELAJ W KIERUNKU, W KTÓRYM PATRZY WIEŻYCZKA (p.angle), 
          // a nie w stronę obliczaną na nowo z cos/sin
          p.shoot(p.x + cos(playerGunAngle), p.y + sin(playerGunAngle));
          p.shootCooldown = p.shootInterval;
        }
        continue; 
      }
    // 3. Sprawdź dżojstik (Lewa strona)
      if (tx < width * 0.5) {
        joyTouchId = i;
        foundJoyTouch = true;
      }
    }
  }
  
  // Jeśli nie znaleziono dotknięcia dżojstika, zresetuj
  if (!foundJoyTouch) {
    joyTouchId = -1;
  }
  
  // Jeśli nie znaleziono dotknięcia przycisku, zresetuj
  if (!foundShootTouch) {
    shootTouchId = -1;
  }
}

void checkMenuTouch() {
  // Sprawdź dotknięcia w menu
  if (touches.length > 0 && touches[0] != null) {
    float tx = touches[0].x;
    float ty = touches[0].y;
    
      // Przycisk ROZPOCZNIJ (START GAME)
      if (tx > width/2 - 175 && tx < width/2 + 175 &&
          ty > height/2 - 35 && ty < height/2 + 35) {
        
        gameState = GameStatus.TUTORIAL;
        tutorialStep = 0;
        
        // 1. NAJPIERW OBLICZ SIATKĘ
        calculateTilesize(15); 
        
        // 2. POTEM STWÓRZ GRACZA (teraz pobierze aktualne tileSize)
        p = new Player(); 
        
        // 3. GENERUJ MAPĘ I RESETUJ CZAS
        generateMap();
        lastTime = millis() / 1000.0;
    }
    
    // Przycisk WYJŚCIE
    if (tx > width/2 - 175 && tx < width/2 + 175 &&
        ty > height/2 + 65 && ty < height/2 + 135) {
      exit();
    }
  }
}

void checkPauseTouch() {
  for (int i = 0; i < touches.length; i++) {
    if (touches[i] == null) continue;
    float tx = touches[i].x;
    float ty = touches[i].y;

    if (tx > width/2 - 175 && tx < width/2 + 175) {
      
      // LOGIKA DLA TUTORIALA (Tylko 2 przyciski)
      if (previousState == GameStatus.TUTORIAL) {
        if (ty > height/2 + 10 && ty < height/2 + 90) { // RESUME (obniżone)
          gameState = GameStatus.TUTORIAL;
          lastTime = millis() / 1000.0;
        }
        else if (ty > height/2 + 110 && ty < height/2 + 190) { // QUIT (obniżone)
          gameState = GameStatus.MENU;
          resetGame();
        }
      } 
      
      // LOGIKA DLA GRY (3 przyciski)
      else {
        if (ty > height/2 - 75 && ty < height/2 - 5) { // RESUME
          gameState = GameStatus.PLAY;
          lastTime = millis() / 1000.0;
        }
        else if (ty > height/2 + 25 && ty < height/2 + 95) { // RESTART
          gameState = GameStatus.PLAY;
          resetGame();
          lastTime = millis() / 1000.0;
        }
        else if (ty > height/2 + 125 && ty < height/2 + 195) { // QUIT
          gameState = GameStatus.MENU;
          resetGame();
        }
      }
    }
  }
}

void checkEndScreenTouch() {
  if (touches != null && touches.length > 0) {
    for (int i = 0; i < touches.length; i++) {
      if (touches[i] == null) continue;
      
      float tx = touches[i].x;
      float ty = touches[i].y;
      
      // Sprawdzamy obszar wokół środka ekranu (szerokość 350, wysokość 70)
      if (tx > width/2 - 175 && tx < width/2 + 175) {
        
        // Przycisk RESTART / PLAY AGAIN (by = height/2 + 60)
        if (ty > height/2 + 25 && ty < height/2 + 95) {
          gameState = GameStatus.PLAY;
          resetGame();
          lastTime = millis() / 1000.0;
        }
        
        // Przycisk MAIN MENU (by = height/2 + 160)
        if (ty > height/2 + 125 && ty < height/2 + 195) {
          gameState = GameStatus.MENU;
          resetGame();
        }
      }
    }
  }
}

// ============================================================
// RYSOWANIE KONTROLI DOTYKOWYCH
// ============================================================

void drawJoystick() {
  pushStyle();
  
  // TŁO DŻOJSTIKA: Zmieniamy 150 na np. 60-80 dla większej przeźroczystości
  fill(0, 0, 0, 70); // 70 to bardzo delikatne, ciemne kółko
  noStroke();
  ellipse(joyX, joyY, joyRadius * 2, joyRadius * 2);
  
  // Środek (krzyżyk): też możemy go osłabić
  //stroke(255, 100); // 100 zamiast 200
  //strokeWeight(2);
  //line(joyX - 30, joyY, joyX + 30, joyY);
  //line(joyX, joyY - 30, joyX, joyY + 30);

  // KCIUK (gałka): 
  float thumbX = joyX;
  float thumbY = joyY;
  
  if (joyTouchId != -1 && touches != null && joyTouchId < touches.length && touches[joyTouchId] != null) {
    thumbX = touches[joyTouchId].x;
    thumbY = touches[joyTouchId].y;
    
    float distance = dist(joyX, joyY, thumbX, thumbY);
    if (distance > joyRadius - thumbRadius) {
      float angle = atan2(thumbY - joyY, thumbX - joyX);
      thumbX = joyX + cos(angle) * (joyRadius - thumbRadius);
      thumbY = joyY + sin(angle) * (joyRadius - thumbRadius);
    }
  }
  
  // GAŁKA: Też zróbmy ją bardziej przeźroczystą (np. 120 zamiast 200)
  fill(255, 255, 255, 120); 
  ellipse(thumbX, thumbY, thumbRadius * 2, thumbRadius * 2);
  
  popStyle();
}

void drawShootButton() {
  pushStyle();
  // Przycisk strzału
  fill(255, 50, 50, shootTouchId != -1 ? 255 : 200);
  noStroke();
  ellipse(shootButtonX, shootButtonY, 200, 200);
  
  // Obwódka
  stroke(255, 200);
  strokeWeight(3);
  noFill();
  ellipse(shootButtonX, shootButtonY, 220,220);
  
  // Ikonka strzału
  fill(255);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("FIRE", shootButtonX, shootButtonY);
  
  // Mały celownik
  //stroke(255);
  //strokeWeight(2);
  //line(shootButtonX - 25, shootButtonY, shootButtonX + 25, shootButtonY);
  //line(shootButtonX, shootButtonY - 25, shootButtonX, shootButtonY + 25);
  popStyle();
}

void drawPauseButton() {
  pushStyle();
  fill(0, 0, 0, 100); // Półprzezroczyste tło
  stroke(255);
  strokeWeight(2);
  rectMode(CORNER);
  rect(pauseBtnMargin, pauseBtnMargin, pauseBtnSize, pauseBtnSize, 10);
  
  // Ikona pauzy (dwie kreski)
  fill(255);
  noStroke();
  rect(pauseBtnMargin + 25, pauseBtnMargin + 20, 10, 40);
  rect(pauseBtnMargin + 45, pauseBtnMargin + 20, 10, 40);
  popStyle();
}

// ============================================================
// LOGIKA GRY (z obsługą dotyku)
// ============================================================

void updateGameLogic(float deltaTime) {
  p.update(deltaTime);
  // Aktualizuj ruch gracza na podstawie dżojstika
  float dx = 0;
  float dy = 0;
  
  // POPRAWKA: zawsze sprawdzaj czy touches istnieje
  if (joyTouchId != -1 && touches != null && joyTouchId < touches.length && touches[joyTouchId] != null) {
    float moveX = touches[joyTouchId].x - joyX;
    float moveY = touches[joyTouchId].y - joyY;
    
    float distance = dist(joyX, joyY, touches[joyTouchId].x, touches[joyTouchId].y);
    if (distance > 10) {
      dx = moveX / (joyRadius - thumbRadius);
      dy = moveY / (joyRadius - thumbRadius);
      
      dx = constrain(dx, -1, 1);
      dy = constrain(dy, -1, 1);
    }
  }
  
  // Aktualizuj pozycję gracza
  p.move(dx, dy, deltaTime);
  p.updateMissles(deltaTime);
  
  // Aktualizuj efekty
  for (Explosion ex : explosions) {
    ex.update(deltaTime);
  }
  
  for (Spark s : sparks) {
    s.update(deltaTime);
  }
  
  // Aktualizuj wrogów
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    
    e.update(deltaTime);
    e.updateMissles(deltaTime);
    
    if (isHit(e, p.missles)) {
      explosions.add(new Explosion(e.x, e.y));
      if (!e.subtractHP(10)) {
        shakeAmount = 15;
        enemies.remove(i);
      }
    }
    
    if (isHit(p, e.missles)) {
      explosions.add(new Explosion(p.x, p.y));
      if (!p.subtractHP(10)) {
        shakeAmount = 30;
        gameState = GameStatus.GAMEOVER;
      } else {
        shakeAmount = 5;
      }
    }
  }
}

void checkWinLose() {
  if (enemies.size() == 0) {
    gameState = GameStatus.WIN;
  }
}

void resetGame() {
  
  joyTouchId = -1;
  shootTouchId = -1;
  
  p = new Player();
  enemies.clear(); 
  generateMap();
  
  // Dodajemy wrogów tylko jeśli faktycznie gramy (nie w tutorialu)
  if (gameState == GameStatus.PLAY || (gameState == GameStatus.PAUSE && previousState == GameStatus.PLAY)) {
    numberOfEnemies = int(desiredCols * 0.15);
    generatEnemies(numberOfEnemies);
  }
  
  explosions.clear();
  sparks.clear();
}

// ============================================================
// GENEROWANIE ŚWIATA
// ============================================================

void generatEnemies(int ratio) {
  enemies = new ArrayList<Enemy>();
  for (int i=0; i<ratio; i++) {
    enemies.add(new Enemy());
  }
}

void generateMap() {
  map = new int[cols][rows];
  tileHP = new float[cols][rows];

  if (gameState == GameStatus.TUTORIAL) {
    // Mapa tutorialowa
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (x == 0 || y == 0 || x == cols-1 || y == rows-1) {
          map[x][y] = 1;
          tileHP[x][y] = maxTileHP;
        } else {
          map[x][y] = 0;
          tileHP[x][y] = 0;
        }
      }
    }
    // Jeden blok na środku
    int midX = cols / 2 + 3;
    int midY = rows / 2;
    for (int i=-1; i < 2; i ++) {
      map[midX][midY+i] = 1;
      tileHP[midX][midY+i] = maxTileHP;
    }
  } else {
    // Standardowa mapa gry
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (x == 0 || y == 0 || x == cols-1 || y == rows-1) {
          map[x][y] = 1;
          tileHP[x][y] = maxTileHP;
        } else {
          if (random(1) < 0.12) {
            map[x][y] = 1;
            tileHP[x][y] = maxTileHP;
          } else {
            map[x][y] = 0;
            tileHP[x][y] = 0;
          }
        }
      }
    }
  }

  // Wyczyszczenie startera gracza
  int px = int(p.x / tileSize);
  int py = int(p.y / tileSize);
  for (int dx = -2; dx <= 2; dx++) {
    for (int dy = -2; dy <= 2; dy++) {
      if (px + dx >= 0 && px + dx < cols && py + dy >= 0 && py + dy < rows) {
        map[px + dx][py + dy] = 0;
        tileHP[px + dx][py + dy] = 0;
      }
    }
  }
}

// ============================================================
// SYSTEM KOLIZJI
// ============================================================

boolean collidesPlayer(float x, float y, float PlayerWidth, float PlayerHeight) {
  float halfW = PlayerWidth / 2;
  float halfH = PlayerHeight / 2;

  return
    collidesPoint(x - halfW, y - halfH) ||
    collidesPoint(x + halfW, y - halfH) ||
    collidesPoint(x - halfW, y + halfH) ||
    collidesPoint(x + halfW, y + halfH);
}

boolean collidesPoint(float x, float y) {
  int tx = int(x / tileSize);
  int ty = int(y / tileSize);
  
  if (tx < 0 || ty < 0 || tx >= cols || ty >= rows) return false;
  
  return map[tx][ty] == 1;
}

boolean canSpawnTank(float x, float y, float w, float h) {
  float hw = w / 2;
  float hh = h / 2;

  return
    !collidesPoint(x - hw, y - hh) &&
    !collidesPoint(x + hw, y - hh) &&
    !collidesPoint(x - hw, y + hh) &&
    !collidesPoint(x + hw, y + hh);
}

boolean isHit(Tank tank, ArrayList<Missle> missles) {
  for (int i = 0; i < missles.size(); i++) {
    Missle m = missles.get(i);
    float d = dist(tank.x, tank.y, m.x, m.y);
    
    if (d < tank.heightTank/2 + m.h/2) {
      m.h = 0;
      m.w = 0;
      return true;
    }
  }
  return false;
}

// ============================================================
// RENDEROWANIE
// ============================================================

void drawGameVisuals() {
  pushMatrix();
  
  // Efekt wstrząsu
  if (shakeAmount > 0) {
    translate(random(-shakeAmount, shakeAmount), random(-shakeAmount, shakeAmount));
    shakeAmount *= 0.9;
    if (shakeAmount < 0.5) shakeAmount = 0;
  }

  drawMap();
  
  if (gameState == GameStatus.PLAY || gameState == GameStatus.TUTORIAL) {
    // Zapisz aktualny kąt wieżyczki
    playerGunAngle = p.angle;
    
    float targetX = p.x + cos(playerGunAngle);
    float targetY = p.y + sin(playerGunAngle);
    p.display(targetX, targetY);
  }
  p.displayMissles();
  
  for (Enemy e : enemies) {
    e.display(p.x, p.y);
    e.displayMissles();
  }

  // Iskry
  for (int i = sparks.size()-1; i >= 0; i--) {
    Spark s = sparks.get(i);
    s.display();
    if (!s.alive) sparks.remove(i);
  }
  
  // Wybuchy
  for (int i = explosions.size() - 1; i >= 0; i--) {
    Explosion ex = explosions.get(i);
    ex.display();
    if (!ex.alive) explosions.remove(i);
  }

  popMatrix();
}

void drawMap() {
  pushStyle();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      float posX = x * tileSize;
      float posY = y * tileSize;

      // Zawsze rysuj tło
      drawTileGround(posX, posY, tileSize);
      
      // Rysuj przeszkodę jeśli istnieje
      if (map[x][y] == 1) {
        drawTileBox(posX, posY, tileSize, tileHP[x][y]);
      }
    }
  }
  popStyle();
}

// ============================================================
// TUTORIAL
// ============================================================

void drawTutorialGame() {
  drawGameVisuals();
  
  pushStyle();
  textAlign(CENTER);
  textSize(40);
  fill(0, 150);
  text(getTutorialText(), width/2 + 3, 105);
  fill(255, 255, 0);
  text(getTutorialText(), width/2, 100);
  popStyle();
}

String getTutorialText() {
  switch(tutorialStep) {
    case 0: return "Drag on the left side\nto move your tank";
    case 1: return "Tap the red FIRE button\nto shoot missiles";
    case 2: return "Destroy the obstacle\nwith your cannon";
    case 3: return "Great job! Tap the screen\nto start the battle!";
    default: return "";
  }
}

void updateTutorialLogic() {
  float currentTime = millis() / 1000.0;
  float deltaTime = currentTime - lastTime;
  lastTime = currentTime;

  // --- DODANO: Logika odczytu dżojstika w tutorialu ---
  float dx = 0;
  float dy = 0;
  
  if (joyTouchId != -1 && touches != null && joyTouchId < touches.length && touches[joyTouchId] != null) {
    float moveX = touches[joyTouchId].x - joyX;
    float moveY = touches[joyTouchId].y - joyY;
    
    float distance = dist(joyX, joyY, touches[joyTouchId].x, touches[joyTouchId].y);
    if (distance > 10) {
      dx = moveX / (joyRadius - thumbRadius);
      dy = moveY / (joyRadius - thumbRadius);
      
      dx = constrain(dx, -1, 1);
      dy = constrain(dy, -1, 1);
    }
  }
  
  p.move(dx, dy, deltaTime); // Teraz postać będzie reagować na ruch
  // ----------------------------------------------------

  p.update(deltaTime);
  p.updateMissles(deltaTime);

  for (Explosion ex : explosions) {
    ex.update(deltaTime);
  }
  for (Spark s : sparks) {
    s.update(deltaTime);
  }

  // Warunki przejścia tutorialu (pozostają bez zmian)
  if (tutorialStep == 0 && joyTouchId != -1) {
    tutorialStep = 1;
  } else if (tutorialStep == 1 && shootTouchId != -1) {
    tutorialStep = 2;
    initialWallCount = countWalls();
  } else if (tutorialStep == 2 && countWalls() < initialWallCount) {
    tutorialStep = 3;
  } else if (tutorialStep == 3 && touches.length > 0) {
    gameState = GameStatus.PLAY;
    calculateTilesize(desiredCols);
    resetGame();
    lastTime = millis() / 1000.0;
  }
}
int countWalls() {
  int count = 0;
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (map[x][y] == 1) count++;
    }
  }
  return count;
}

// ============================================================
// INTERFEJS UŻYTKOWNIKA (MENU itp.)
// ============================================================

void drawMenu() {
  pushStyle();
  background(30);
  rectMode(CORNER);
  fill(0, 0, 0, 120);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);

  // Pulsujący tytuł
  float pulse = 1.0 + sin(frameCount * 0.08) * 0.06;
  pushMatrix();
  translate(width/2, height/2 - 180);
  scale(pulse);
  fill(255, 80, 80);
  textSize(80);
  text("TANK BATTLE", 0, 0);
  popMatrix();

  // Podtytuł
  fill(200);
  textSize(24);
  text("Touch to move, FIRE to shoot", width/2, height/2 - 100);

  // Przyciski
  String[] labels = {"START GAME", "EXIT"};
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    float by = height/2 + (i * 100);

    rectMode(CENTER);
    fill(90);
    rect(bx, by, 350, 70, 15);

    fill(255);
    textSize(30);
    text(labels[i], bx, by - 4);
  }

  // Instrukcja
  fill(150);
  textSize(18);
  text("Controls: Joystick + FIRE Button", width/2, height - 60);

  popStyle();
}

void drawPauseMenu() {
  pushStyle();
  rectMode(CORNER);
  fill(0, 0, 0, 180);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(60);
  text("PAUSED", width/2, height/2 - 180);

  // DYNAMICZNA LISTA PRZYCISKÓW
  String[] labels;
  if (previousState == GameStatus.TUTORIAL) {
    labels = new String[] {"RESUME", "QUIT TO MENU"};
  } else {
    labels = new String[] {"RESUME", "RESTART", "QUIT TO MENU"};
  }
  
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    // Przesuwamy przyciski niżej, jeśli są tylko dwa, żeby ładnie wyglądało
    float offset = (labels.length == 2) ? 50 : 0;
    float by = height/2 - 40 + (i * 100) + offset;
    
    rectMode(CENTER);
    fill(100);
    rect(bx, by, 350, 70, 12);
    
    fill(255);
    textSize(28);
    text(labels[i], bx, by - 5);
  }
  popStyle();
}

void gameOver() {
  drawEndScreen("GAME OVER", color(255, 0, 0));
}

void Win() {
  drawEndScreen("VICTORY", color(0, 255, 0));
}

void drawEndScreen(String title, color titleColor) {
  pushStyle();
  rectMode(CORNER);
  fill(0, 0, 0, 180);
  rect(0, 0, width, height);
  
  textAlign(CENTER, CENTER);

  float pulse = 1.0 + sin(frameCount * 0.1) * 0.05;
  pushMatrix();
  translate(width/2, height/2 - 150);
  scale(pulse);
  fill(titleColor);
  textSize(70);
  text(title, 0, 0);
  popMatrix();

  // Statystyki
  fill(200);
  textSize(32);
  text("Survived: " + int(p.hp) + " HP", width/2, height/2 - 50);
  text("Enemies destroyed: " + (numberOfEnemies - enemies.size()), width/2, height/2);

  String[] labels = {"PLAY AGAIN", "MAIN MENU"};
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    float by = height/2 + 60 + (i * 100);
    
    rectMode(CENTER);
    fill(100);
    rect(bx, by, 350, 70, 12);
    
    fill(255);
    textSize(28);
    text(labels[i], bx, by - 5);
  }
  popStyle();
}

void drawNotification() {
  int elapsed = millis() - notificationTime;
  
  if (elapsed < displayDuration) {
    pushStyle();
    float alpha = map(elapsed, 0, displayDuration, 255, 0);
    textAlign(CENTER);
    textSize(36);
    fill(255, 255, 0, alpha);
    text(notificationText, width/2, 80);
    popStyle();
  }
}

void showNotify(String msg) {
  notificationText = msg;
  notificationTime = millis();
}

// ============================================================
// OBSŁUGA PRZYCISKÓW FIZYCZNYCH (ANDROID)
// ============================================================

void keyPressed() {
  // Przycisk BACK na Androidzie
  if (keyCode == BACK) {
    if (gameState == GameStatus.PLAY || gameState == GameStatus.TUTORIAL) {
      previousState = gameState;
      gameState = GameStatus.PAUSE;
    } else if (gameState == GameStatus.PAUSE) {
      gameState = previousState;
      lastTime = millis() / 1000.0;
    } else if (gameState == GameStatus.MENU) {
      exit();
    }
    key = 0;
  }
}
