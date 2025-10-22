# Agriwing-simulator

## Dependências

Instalar no host (com ubuntu 22.04 ou 24.04)

- [pixi](https://pixi.sh/latest/installation/)
- [gz harmonic](https://gazebosim.org/docs/harmonic/install_ubuntu/)

## Setup

Clone px4-autopilot and switch to release/1.16 branch

```bash
git clone https://github.com/PX4/PX4-Autopilot.git
git switch release/1.16
```

Clonar demais repositórios

```bash
git submodule update --init --recursive
```

Copy agriwing custom models and world to PX4-Autopilot project

```bash
./agriwing-simulation/scripts/copy_models.sh
```

Substituir arquivo do airframe em /models

Setup the simulation world

```bash
export PX4_GZ_WORLD=agriwing
```

run the simulation

```bash
make px4_sitl gz_x500_mono_cam_down
```

run gz-ros bridge

```bash
python3 gz_cam_bridge.py
```

---

## TODO

- [x] Adicionar base de docagem com marcadores
- [ ] Adicionar marcadores vermelhos
- [ ] Adicionar eletrodo
- [ ] Adicionar laser-scan para simular distance sensor / tf-luna
- [ ] Adicionar plantação simplificada
