package vanetmec.simulations.SimpleVanetMEC;

// ── INET ──────────────────────────────────────────────────────
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.networklayer.ipv4.RoutingTableRecorder;
import inet.node.ethernet.Eth10G;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;

// ── Simu5G ────────────────────────────────────────────────────
import simu5g.world.radio.LteChannelControl;
import simu5g.common.binder.Binder;
import simu5g.common.carrierAggregation.CarrierAggregation;
import simu5g.nodes.Upf;
import simu5g.nodes.NR.gNodeB;
import simu5g.nodes.cars.NRCar;         
import simu5g.nodes.mec.MECHost;
import simu5g.nodes.mec.MECOrchestrator.MecOrchestrator;
import simu5g.nodes.mec.UALCMP.UALCMP;

// ── Veins ─────────────────────────────────────────────────────
import org.car2x.veins.subprojects.veins_inet.VeinsInetManager;

//
// MecVanetGrid
//
// A VANET simulation with:
//   - SUMO-controlled NRCar vehicles (via Veins/TraCI)
//   - Two gNodeBs covering a grid road map
//   - Two MEC Hosts with Location Service
//   - MEC Orchestrator + UALCMP for app lifecycle management
//
network MecVanetGrid
{
    parameters:
        double playgroundSizeX @unit(m);
        double playgroundSizeY @unit(m);
        double playgroundSizeZ @unit(m);
        @display("bgb=1100,700");

    submodules:

        // ── Infrastructure ────────────────────────────────────
        channelControl: LteChannelControl {
            @display("p=50,25;is=s");
        }
        routingRecorder: RoutingTableRecorder {
            @display("p=50,75;is=s");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=50,125");
            config = xmldoc("demo.xml");
        }
        binder: Binder {
            @display("p=50,175;is=s");
        }
        carrierAggregation: CarrierAggregation {
            @display("p=50,225;is=s");
        }

        // ── Veins/SUMO integration ────────────────────────────
        veinsManager: VeinsInetManager {
            @display("p=50,300;is=s");
        }

        // ── 5G Core ───────────────────────────────────────────
        server: StandardHost {
            @display("p=900,60;i=device/server");
        }
        router: Router {
            @display("p=750,60");
        }
        upf: Upf {
            @display("p=600,60");
        }
        iUpf1: Upf {
            @display("p=350,200");
        }
        iUpf2: Upf {
            @display("p=750,200");
        }

        // ── Radio Access ──────────────────────────────────────
        gnb1: gNodeB {
            @display("p=250,400;is=vl");
        }
        gnb2: gNodeB {
            @display("p=750,400;is=vl");
        }

        // ── MEC Layer ─────────────────────────────────────────
        mecHost1: MECHost {
            @display("p=250,200");
        }
        mecHost2: MECHost {
            @display("p=750,200");          // closer to gnb2
        }
        mecOrchestrator: MecOrchestrator {
            @display("p=400,60");
        }
        ualcmp: UALCMP {
            @display("p=500,60");
        }

        // ── Vehicle placeholder (Veins fills this at runtime) ─
        car[0]: NRCar; // fixed number of cars 

    connections allowunconnected:

        //# Internet-side (router owns filterGate — the upstream/DN port)
        server.pppg++  <--> Eth10G <--> router.pppg++;
        router.pppg++  <--> Eth10G <--> upf.filterGate;

        //# Core UPF to intermediate UPFs
        upf.pppg++  <--> Eth10G <--> iUpf1.pppg++;
        upf.pppg++  <--> Eth10G <--> iUpf2.pppg++;

        //# Intermediate UPFs to gNodeBs
        iUpf1.pppg++ <--> Eth10G <--> gnb1.ppp;
        iUpf2.pppg++ <--> Eth10G <--> gnb2.ppp;

        //# MEC Hosts to intermediate UPFs
        mecHost1.ppp++ <--> Eth10G <--> iUpf1.pppg++;
        mecHost2.ppp++ <--> Eth10G <--> iUpf2.pppg++;

        //# UALCMP management plane — use pppg++ (vector gate)
        //# ualcmp.ppp++  <--> Eth10G <--> upf.pppg++;

        ualcmp.ppp++   <--> Eth10G <--> router.pppg++;

        //# MEC Orchestrator control plane (no network cable, direct gates)
        ualcmp.toMecOrchestrator   --> mecOrchestrator.fromUALCMP;
        ualcmp.fromMecOrchestrator <-- mecOrchestrator.toUALCMP;

        //# X2 between gNodeBs
        gnb1.x2++ <--> Eth10G <--> gnb2.x2++;
}