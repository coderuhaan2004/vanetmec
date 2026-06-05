# MecVanet
Multi-Access Edge Computing in Vehicular AdHoc Networks

## Setting up the docker container in WSL
- Make sure `docker` is installed
- Run `./build.sh`

## Running the simulation
### Project References (In OMNet++ IDE)
- Copy this project into the `docker` container (For `docker` users).
- Make sure that the project refers to the source folders of the frameworks.
- Go to **File** tab -> **Open Projects from File System**, search for the root directory of the following frameworks:
    - `inet`
    - `simu5G`
    - `veins`
- For **Project References**: Right-click project → **Properties → Project References** → tick `inet`, `simu5g`, `veins`, `veins_inet`. This automatically makes their NED roots available.

- In run.sh change the necessary paths
    - ```bash
    # ── Edit these paths to match your installation ───────────────
    INET_ROOT=../../../inet4.5
    SIMU5G_ROOT=../../../Simu5G-1.2.2
    VEINS_ROOT=../../../veins-veins-5.3.1
    VEINS_INET_ROOT=../../../veins-veins-5.3.1/subprojects/veins_inet
    ```

### Running with GUI (Qtenv)
Start `sumo` in one terminal before running the simulation:
```bash
/home/ubuntu/omnetpp-6.2.0/workspace/
vanetmec/simulations# ../../../veins-veins-5.3.1/bin/veins_launchd -vv -c sumo
```

```bash
./run -u Qtenv
```