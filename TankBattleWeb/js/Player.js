class Player extends Tank {
     constructor(x, y, speed, hp, type) {
        super(x, y, speed, hp, type);
        this.shootCooldown = 0;  // Dodaj cooldown
        this.shootInterval = 0.3;  // 0.3 sekundy między strzałami
    }
    
    update(dt) {
        // Zmniejsz cooldown
        if (this.shootCooldown > 0) {
            this.shootCooldown -= dt;
        }
        
        if (this.hp < this.maxHp * 0.5) {
            this.speed = this.maxSpeed * 0.7;
        } else {
            this.speed = this.maxSpeed;
        }
        
        let dx = 0, dy = 0;
    // Sprawdź Set
    if (keysPressed.has('w') || keysPressed.has('arrowup')) dy -= 1;
    if (keysPressed.has('s') || keysPressed.has('arrowdown')) dy += 1;
    if (keysPressed.has('a') || keysPressed.has('arrowleft')) dx -= 1;
    if (keysPressed.has('d') || keysPressed.has('arrowright')) dx += 1;
        
        this.move(dx, dy, dt);
    }
    
    shoot(targetX, targetY) {
        // Sprawdź cooldown przed strzałem
        if (this.shootCooldown <= 0) {
            let gunAngle = Math.atan2(targetY - this.y, targetX - this.x);
            let gunLength = this.widthTank/2 + this.widthTank/3;
            let sx = this.x + Math.cos(gunAngle) * gunLength;
            let sy = this.y + Math.sin(gunAngle) * gunLength;
            this.missles.push(new Missle(sx, sy, gunAngle, this.type));
            this.shootCooldown = this.shootInterval;  // Zresetuj cooldown
        }
    }
}