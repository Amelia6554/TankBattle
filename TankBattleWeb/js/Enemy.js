class Enemy extends Tank {
   constructor(x, y, speed, hp, type) {
        super(x, y, speed, hp, type);
        
        this.changeTimer = 0;
        this.shootCooldown = 0;
        this.shootInterval = 1.2;
        
        // ZAINICJALIZUJ POZYCJĘ W OSOBNEJ METODZIE
        this.initPosition();
    }
    
    initPosition() {
        // Upewnij się, że tileSize jest zdefiniowane
        if (tileSize && p) {
            let minDist = tileSize * 6;
            let attempts = 0;
            const maxAttempts = 100;
            
            do {
                this.x = random(width);
                this.y = random(height);
                attempts++;
                // Bezpiecznik: jeśli po 100 próbach nie znajdziemy miejsca, użyj domyślnego
                if (attempts >= maxAttempts) {
                    this.x = width * 0.75;
                    this.y = height * 0.25;
                    break;
                }
            } while (
                !canSpawnTank(this.x, this.y, this.widthTank, this.heightTank) ||
                dist(this.x, this.y, p.x, p.y) < minDist
            );
            
            this.viewDistance = tileSize * 6;
        } else {
            // Tymczasowe wartości
            this.x = 300;
            this.y = 300;
            this.viewDistance = 150;
        }
    }
    
    
    update(dt) {

        if (this.viewDistance === undefined) {
            this.initPosition();
        }

        this.changeTimer -= dt;
        this.shootCooldown -= dt;
        
        let dx = 0;
        let dy = 0;
        let distToPlayer = dist(this.x, this.y, p.x, p.y);
        
        if (this.hp < this.maxHp * 0.5) {
            this.speed = this.maxSpeed * 0.7;
        } else {
            this.speed = this.maxSpeed;
        }
        
        if (distToPlayer < this.viewDistance) {
            // Tryb ścigania
            dx = p.x - this.x;
            dy = p.y - this.y;
            let len = Math.sqrt(dx*dx + dy*dy);
            if (len > 0) {
                dx /= len;
                dy /= len;
            }
            
            // Strzelanie do gracza
            if (this.shootCooldown <= 0) {
                this.shoot(p.x, p.y);
                this.shootCooldown = this.shootInterval;
            }
        } else {
            // Tryb patrolowania
            if (this.changeTimer <= 0) {
                let a = random(TWO_PI);
                dx = Math.cos(a);
                dy = Math.sin(a);
                this.changeTimer = 1.5;
            } else {
                dx = this.vx / this.speed;
                dy = this.vy / this.speed;
            }
        }
        
        this.move(dx, dy, dt);
    }
}