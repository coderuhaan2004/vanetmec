package vanetmec.simulations.TaskOffloadVanet;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;

import simu5g.common.binder.Binder;
import simu5g.common.carrierAggregation.CarrierAggregation;
import simu5g.world.radio.LteChannelControl;
import simu5g.nodes.Upf;
import simu5g.nodes.NR.gNodeB;
import simu5g.nodes.cars.NRCar;
import simu5g.nodes.mec.MECHost;
import simu5g.nodes.mec.MECOrchestrator.MecOrchestrator;
import simu5g.nodes.mec.UALCMP.UALCMP;

import org.car2x.veins.subprojects.veins_inet.VeinsInetManager;
import org.car2x.veins.base.modules.BaseWorldUtility;
import org.car2x.veins.modules.world.annotations.AnnotationManager;
import org.car2x.veins.modules.obstacle.ObstacleControl;
import org.car2x.veins.visualizer.roads.RoadsCanvasVisualizer;

network CityMecVanet
{
    parameters:
        // double playgroundSizeX @unit(m);
        // double playgroundSizeY @unit(m);
        // double playgroundSizeZ @unit(m);
        // @display("bgb=dropUnit($playgroundSizeX),dropUnit($playgroundSizeY)");
        @display("bgb=2607,3010");

    types:
        channel Eth10G extends ned.DatarateChannel
        {
            datarate = 10Gbps;
            delay = 0.5us;
        }

    submodules:
        channelControl:    LteChannelControl       { @display("p=60,30;is=s");  }
        binder:            Binder                  { @display("p=170,30;is=s"); }
        carrierAggregation: CarrierAggregation     { @display("p=280,30;is=s"); }
        configurator:      Ipv4NetworkConfigurator {
            @display("p=390,30;is=s");
            config = xmldoc("demo.xml");
        }
        manager: VeinsInetManager { @display("p=500,30;is=s"); }

        server: StandardHost { @display("p=1000,100"); }
        router: Router       { @display("p=600,100");  }
        upf:    Upf          { @display("p=600,250");  }

        // One iUpf per gNB — MEC data stays local to the edge cluster
        iUpf1: Upf { @display("p=900,1200"); }
        iUpf2: Upf { @display("p=1600,1000"); }
        iUpf3: Upf { @display("p=2300,1300"); }

        ualcmp:          UALCMP          { @display("p=350,100"); }
        mecOrchestrator: MecOrchestrator { @display("p=350,200"); }

        gnb1: gNodeB { @display("p=200,580;is=vl"); }
        gnb2: gNodeB { @display("p=600,580;is=vl"); }
        gnb3: gNodeB { @display("p=1000,580;is=vl"); }

        mecHost1: MECHost { @display("p=900,1100"); }
        mecHost2: MECHost { @display("p=1600,900"); }
        mecHost3: MECHost { @display("p=2300,1200"); }

        // Dynamic vector — Veins/SUMO owns the size at runtime
        car[0]: NRCar { @display("p=500,750"); }

        // City Scenario setup
        obstacles: ObstacleControl {
            @display("p=240,50");
        }
        annotations: AnnotationManager {
            @display("p=260,50");
        }
        // world: BaseWorldUtility {
        //     playgroundSizeX = veins_eval_by_version(veins_omnetpp_buildnum(), "playgroundSizeX", 1525, "parent.playgroundSizeX");
        //     playgroundSizeY = veins_eval_by_version(veins_omnetpp_buildnum(), "playgroundSizeY", 1525, "parent.playgroundSizeY");
        //     playgroundSizeZ = veins_eval_by_version(veins_omnetpp_buildnum(), "playgroundSizeZ", 1525, "parent.playgroundSizeZ");
        //     @display("p=30,0;i=misc/globe");
        // }
        world: BaseWorldUtility {
            parameters:
                playgroundSizeX = 2607m;
                playgroundSizeY = 3010m;
                playgroundSizeZ = 50m;
                @display("p=30,0;i=misc/globe");
        }
        roadsCanvasVisualizer: RoadsCanvasVisualizer {
            @display("p=300,0");
        }

    connections allowunconnected:

        // Internet side
        server.pppg++ <--> Eth10G <--> router.pppg++;
        router.pppg++ <--> Eth10G <--> upf.filterGate;

        // Core UPF to each iUpf
        upf.pppg++ <--> Eth10G <--> iUpf1.pppg++;
        upf.pppg++ <--> Eth10G <--> iUpf2.pppg++;
        upf.pppg++ <--> Eth10G <--> iUpf3.pppg++;

        // iUpf to its gNB
        iUpf1.pppg++ <--> Eth10G <--> gnb1.ppp;
        iUpf2.pppg++ <--> Eth10G <--> gnb2.ppp;
        iUpf3.pppg++ <--> Eth10G <--> gnb3.ppp;

        // MEC hosts on the edge side of their iUpf
        mecHost1.ppp++ <--> Eth10G <--> iUpf1.pppg++;
        mecHost2.ppp++ <--> Eth10G <--> iUpf2.pppg++;
        mecHost3.ppp++ <--> Eth10G <--> iUpf3.pppg++;

        // UALCMP management plane — through router (not upf.pppg++)
        ualcmp.ppp++ <--> Eth10G <--> router.pppg++;

        // MecOrchestrator: control-plane gates only, no network cable
        ualcmp.toMecOrchestrator   --> mecOrchestrator.fromUALCMP;
        ualcmp.fromMecOrchestrator <-- mecOrchestrator.toUALCMP;

        // X2 full mesh — connection order determines x2ppp index
        gnb1.x2++ <--> Eth10G <--> gnb2.x2++;   // gnb1:x2ppp0, gnb2:x2ppp0
        gnb2.x2++ <--> Eth10G <--> gnb3.x2++;   // gnb2:x2ppp1, gnb3:x2ppp0
        gnb1.x2++ <--> Eth10G <--> gnb3.x2++;   // gnb1:x2ppp1, gnb3:x2ppp1
}