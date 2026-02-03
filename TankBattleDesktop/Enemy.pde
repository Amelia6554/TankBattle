enum State { WANDER, CHASE }

class Enemy extends Tank {
  float dirX, dirY;
  float changeTimer = 0; // Licznik do zmiany kierunku w trybie patrolowania
  float shootCooldown = 0;
  float shootInterval = 1.2; // Odstęp czasowy między strzałami przeciwnika
  State state = State.WANDER;

  float viewDistance = tileSize * 6; // Zasięg detekcji gracza

  Enemy(PShape imgBottom, PShape imgGun, PShape imgMissile) {
    super(0, 0, 50, 100, imgBottom, imgGun, imgMissile);
    float minDist = tileSize * 6;

    // Losowanie pozycji startowej z dala od gracza i poza przeszkodami
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
    
    // Algorytm przełączania stanów maszyny stanów (FSM)
    if (distToPlayer < viewDistance) {
      state = State.CHASE;
    } else {
      state = State.WANDER;
    }

    // Skalowanie prędkości w zależności od poziomu uszkodzeń pancerza
    if (hp < maxHp * 0.5) {
      speed = maxSpeed * 0.7; // Redukcja mobilności przy niskim HP
    } else {
      speed = maxSpeed;
    }

    // Logika zachowania SI
    if (state == State.CHASE) {
      // Śledzenie pozycji gracza i wyznaczanie wektora kierunku
      dx = p.x - x;
      dy = p.y - y;

      float len = sqrt(dx*dx + dy*dy);
      dx /= len; // Normalizacja wektora
      dy /= len;

      // Automatyczny ostrzał po namierzeniu celu
      if (shootCooldown <= 0) {
        shoot(p.x, p.y);
        shootCooldown = shootInterval;
      }
    } else { // WANDER - ruch losowy/patrolowy
      if (changeTimer <= 0) {
        float a = random(TWO_PI);
        dx = cos(a);
        dy = sin(a);
        changeTimer = 1.5;
      } else {
        // Kontynuacja ruchu w zadanym kierunku
        dx = vx / speed;
        dy = vy / speed;
      }
    }
    
    move(dx, dy, dt);
  }
}