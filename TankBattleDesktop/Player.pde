class Player extends Tank {

  Player(PShape imgBottom, PShape imgGun, PShape imgMissile) {
    super(width/2, height/2, 200, 500, imgBottom, imgGun, imgMissile);
    maxSpeed = 200;
  }

  void update(float dt) {
    // Najpierw ustal bazową prędkość
    if (hp < maxHp * 0.5) {
        speed = maxSpeed * 0.7; // 70% prędkości jeśli ranny
    } else {
        speed = maxSpeed; // powrót do 100% jeśli uleczony/zdrowy
    }

    float dx = 0, dy = 0;
    if (w) dy -= 1;
    if (s) dy += 1;
    if (a) dx -= 1;
    if (d) dx += 1;
    
    move(dx, dy, dt);
}
}
