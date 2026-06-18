$title IGEMS: Integrated Global Emissions Management System (GAMS 25 implementation)

$onText
-------------------------------------------------------------------------------
 IGEMS - Integrated Global Emissions Management System
 A governance-allocation simulator for global carbon budget allocation.

 Reference: Al-Amin (2025). IGEMS: The Governance Sequence and 1.5 C
 Compatibility.

 This file reproduces the deterministic computations of the IGEMS model:
   1. four allocation mechanisms (market, equity, capacity, hybrid),
   2. a 50-year emissions trajectory (2024 to 2074) under geometric decay,
   3. evaluation metrics: compliance rate, justice index, development
      surplus, per-capita ratio, and the heuristic 1.5 C success probability,
   4. carbon-budget and decarbonization-rate sensitivity,
   5. an OPTIONAL optimisation module that selects hybrid weights.

 Compatibility: written for GAMS 25.x. No solver is needed for the core model
 (Sections 1 to 7). Only the optional Section 8 calls a MIP solver.

 ------------------------------------------------------------------------------
 IMPORTANT NOTE ON THE COMPLIANCE RATE (please read before reporting results)
 ------------------------------------------------------------------------------
 The compliance rate below follows the definition stated in the paper:
   compliant(i,t) = 1 if E(i,t) <= A(i), then averaged over all regions
   and all years. With the published allocations this definition yields:
       market 0.00 | equity 0.35 | capacity 0.61 | hybrid 0.42
 These differ from the workbook headline values in sheet 3_DynamicSim:
       market 0.22 | equity 0.67 | capacity 0.44 | hybrid 0.78
-------------------------------------------------------------------------------
$offText


* ==============================================================
* 1. SETS
* ==============================================================
Set i 'nine macro-regions'
    / NA   'North America'
      EU   'Europe'
      CHN  'China'
      IND  'India'
      SSA  'Sub-Saharan Africa'
      MECA 'Middle East and Central Asia'
      SAS  'South Asia'
      EAP  'East Asia and Pacific'
      LAM  'Latin America' / ;

Set t 'simulation years' / 2024*2074 / ;

Set m 'allocation mechanisms' / market, equity, capacity, hybrid / ;


* ==============================================================
* 2. BASELINE DATA   (Table 1 / sheet 1_Baseline, year 2024)
* ==============================================================
* Columns: pop (billion), gdp ($T, 2024 USD), emis (Gt CO2/yr),
*          hist (cumulative Gt CO2), forest (fraction land cover)
Table d(i,*) 'regional baseline data'
            pop      gdp     emis    hist    forest
   NA       0.58     28.0     6.5    400     0.33
   EU       0.45     19.0     3.6    320     0.35
   CHN      1.43     17.0    11.0     90     0.23
   IND      1.44      3.7     2.4     35     0.23
   SSA      1.20      2.1     1.2     12     0.30
   MECA     0.50      2.8     2.2     18     0.09
   SAS      2.00      4.2     3.2     28     0.17
   EAP      1.80      9.5     4.3     45     0.28
   LAM      0.65      3.4     1.8     35     0.49 ;

Scalars
   B     'annual global carbon budget (Gt CO2 per year)'   / 10    /
   drate 'annual decarbonization rate (fraction)'          / 0.025 / ;

Parameters
   Etot  'total current emissions (Gt CO2/yr)'
   Ptot  'total population (billion)'
   Htot  'total historical emissions (Gt CO2)'
   meanG 'mean GDP per capita (USD)'
   bench 'equal per-capita benchmark (Gt per billion people)'
   gpc(i) 'GDP per capita (USD)' ;

Etot   = sum(i, d(i,'emis'));
Ptot   = sum(i, d(i,'pop'));
Htot   = sum(i, d(i,'hist'));
gpc(i) = d(i,'gdp')/d(i,'pop')*1000;
meanG  = sum(i, d(i,'gdp'))/Ptot*1000;
bench  = B/Ptot;


* ==============================================================
* 3. ALLOCATION MECHANISMS   (Section 3.4 / Table 2)
* ==============================================================
Parameters
   alloc(m,i) 'static allocation (Gt CO2 per year)'
   Bi(i) 'equity per-capita base'
   Hi(i) 'equity historical penalty'
   Di(i) 'equity development bonus'
   Fi(i) 'capacity forest factor'
   Mi(i) 'capacity development multiplier'
   SumFraw 'sum of raw forest cover' ;

* --- Mechanism 1: Market-based (grandfathering) ---
*     A(i) = (E(i)/Etot) * B
alloc('market',i) = d(i,'emis')/Etot*B;

* --- Mechanism 2: Equity-based (CBDR+RC) ---
*     base - historical penalty + development bonus
Bi(i) = d(i,'pop')/Ptot*B;
Hi(i) = d(i,'hist')/Htot*0.40*Bi(i);
* development bonus, layered so each region falls in exactly one band:
*   above mean -> -0.05 ; 0.5 to 1.0 mean -> +0.10 ; below 0.5 mean -> +0.25
Di(i)                        = -0.05*Bi(i);
Di(i)$(gpc(i) <= 1.0*meanG)  =  0.10*Bi(i);
Di(i)$(gpc(i) <  0.5*meanG)  =  0.25*Bi(i);
alloc('equity',i) = Bi(i) - Hi(i) + Di(i);

* --- Mechanism 3: Capacity-based ---
*     numerator uses min(forest*2, 1); denominator is the RAW forest sum.
*     (This reproduces the published Table 2 values exactly.)
Fi(i)   = min(d(i,'forest')*2, 1.0);
SumFraw = sum(i, d(i,'forest'));
* development multiplier, layered downward:
*   >=1.5 mean -> 0.7 ; 0.7 to 1.5 -> 1.0 ; 0.3 to 0.7 -> 1.4 ; <0.3 -> 1.8
Mi(i)                        = 0.7;
Mi(i)$(gpc(i) <  1.5*meanG)  = 1.0;
Mi(i)$(gpc(i) <  0.7*meanG)  = 1.4;
Mi(i)$(gpc(i) <  0.3*meanG)  = 1.8;
alloc('capacity',i) = Fi(i)/SumFraw*B*Mi(i);

* --- Mechanism 4: Hybrid cooperative (weights 40:35:25) ---
Scalars wM 'market weight' /0.40/, wE 'equity weight' /0.35/, wC 'capacity weight' /0.25/ ;
alloc('hybrid',i) = wM*alloc('market',i) + wE*alloc('equity',i) + wC*alloc('capacity',i);


* ==============================================================
* 4. DYNAMIC TRAJECTORY   (Section 3.5 / sheet 4)
* ==============================================================
* Geometric decay, identical across mechanisms: E(i,t) = E(i,0)*(1-d)^(t)
Parameters
   emis(i,t) 'regional emissions path (Gt CO2 per year)'
   glob(t)   'global emissions path (Gt CO2 per year)' ;
emis(i,t) = d(i,'emis') * (1-drate)**(ord(t)-1);
glob(t)   = sum(i, emis(i,t));


* ==============================================================
* 5. EVALUATION METRICS   (Section 3.6)
* ==============================================================
Parameters
   comp(m,i,t) 'compliance indicator (1 if on target)'
   CRy(m,t)    'annual compliance rate'
   CR(m)       'mean compliance rate over the horizon'
   Ji(m,i)     'justice index by region (0 to 100)'
   avgJi(m)    'average justice index'
   DS(i)       'development surplus = equity allocation minus current emissions'
   pcap(m,i)   'per-capita allocation (t CO2 per person)'
   pcratio(m)  'max-to-min per-capita ratio'
   p15(m)      'heuristic 1.5 C success probability (%)' ;

* Compliance: a region is compliant in year t when E(i,t) <= its static target.
comp(m,i,t)$(emis(i,t) <= alloc(m,i)) = 1;
CRy(m,t) = sum(i, comp(m,i,t))/card(i);
CR(m)    = sum(t, CRy(m,t))/card(t);

* Justice index: 100 = perfect per-capita parity; clamped at 0 from below.
*   Ji = 100 - |((A/P) - bench)/bench| * 100
Ji(m,i)  = max(0, 100 - abs((alloc(m,i)/d(i,'pop') - bench)/bench)*100);
avgJi(m) = sum(i, Ji(m,i))/card(i);

* Development surplus uses the equity allocation.
DS(i) = alloc('equity',i) - d(i,'emis');

* Per-capita allocation and inequality ratio.
pcap(m,i)  = alloc(m,i)/d(i,'pop');
pcratio(m) = smax(i, pcap(m,i)) / smin(i, pcap(m,i));

* Heuristic 1.5 C success probability, conditioned on CR:
*   CR > 0.70 -> 85% ; 0.40 <= CR <= 0.70 -> 50% ; CR < 0.40 -> 20%
p15(m)                  = 20;
p15(m)$(CR(m) >= 0.40)  = 50;
p15(m)$(CR(m) >  0.70)  = 85;

* Published workbook headline values, kept for side-by-side comparison.
Parameter refCR(m)  / market 0.22, equity 0.67, capacity 0.44, hybrid 0.78 / ;
Parameter refP15(m) / market 20,   equity 50,   capacity 50,   hybrid 85   / ;


* ==============================================================
* 6. REPORTS
* ==============================================================
display Etot, Ptot, Htot, meanG, bench, gpc;
display alloc, glob;
display CR, refCR, p15, refP15, avgJi, pcratio, DS;

Parameter summary(m,*) 'mechanism summary' ;
summary(m,'alloc_sum') = sum(i, alloc(m,i));
summary(m,'CR_formula')= CR(m);
summary(m,'CR_paper')  = refCR(m);
summary(m,'avgJi')     = avgJi(m);
summary(m,'pc_ratio')  = pcratio(m);
summary(m,'p15_pct')   = p15(m);
display summary;


* ==============================================================
* 7. SENSITIVITY   (Section 3.9 / sheet 8)
* ==============================================================
* --- 7A. Carbon-budget sensitivity (IPCC AR6 range, annual ceiling) ---
Set bs 'budget scenarios' / b300, b400, b500, b900 / ;
Parameter Bann(bs) 'annual ceiling (Gt CO2/yr)' / b300 7.5, b400 10, b500 12.5, b900 22.5 / ;
Parameters
   albs(bs,m,i) 'allocation under each budget'
   CRbs(bs,m)   'mean compliance under each budget'
   p15bs(bs,m)  'success probability under each budget' ;

Scalar Bsave 'store base budget' ; Bsave = B;
loop(bs,
   B = Bann(bs);
   albs(bs,'market',i)   = d(i,'emis')/Etot*B;
   Bi(i) = d(i,'pop')/Ptot*B;
   Hi(i) = d(i,'hist')/Htot*0.40*Bi(i);
   Di(i)                       = -0.05*Bi(i);
   Di(i)$(gpc(i) <= 1.0*meanG) =  0.10*Bi(i);
   Di(i)$(gpc(i) <  0.5*meanG) =  0.25*Bi(i);
   albs(bs,'equity',i)   = Bi(i) - Hi(i) + Di(i);
   albs(bs,'capacity',i) = Fi(i)/SumFraw*B*Mi(i);
   albs(bs,'hybrid',i)   = wM*albs(bs,'market',i) + wE*albs(bs,'equity',i) + wC*albs(bs,'capacity',i);
*  emissions path is budget-independent, so reuse emis(i,t)
   CRbs(bs,m) = sum(t, sum(i$(emis(i,t) <= albs(bs,m,i)), 1)) / (card(i)*card(t));
   p15bs(bs,m)                       = 20;
   p15bs(bs,m)$(CRbs(bs,m) >= 0.40)  = 50;
   p15bs(bs,m)$(CRbs(bs,m) >  0.70)  = 85;
);
B = Bsave;
display CRbs, p15bs;

* --- 7B. Decarbonization-rate sensitivity (2074 global endpoint) ---
Set rs 'rate scenarios' / r15, r20, r25, r30, r35 / ;
Parameter rval(rs) 'annual rate' / r15 0.015, r20 0.020, r25 0.025, r30 0.030, r35 0.035 / ;
Parameter end2074(rs) 'global emissions in 2074 (Gt CO2)' ;
end2074(rs) = sum(i, d(i,'emis')*(1-rval(rs))**(card(t)-1));
display end2074;


* ==============================================================
* 8. OPTIONAL: hybrid-weight optimisation (MIP, needs a solver)
* ==============================================================
* The paper notes that the 40:35:25 weights are a policy choice, not a unique
* optimum. This block selects weights that maximise total compliant
* region-years. To run it, uncomment the solve and display lines below.
Parameters mA(i), eA(i), cA(i) ;
mA(i) = alloc('market',i);
eA(i) = alloc('equity',i);
cA(i) = alloc('capacity',i);
Scalar Mbig 'big-M constant' ; Mbig = smax(i, d(i,'emis')) + 1;

Variable        zobj 'compliant region-years' ;
Positive Variables wmv 'market weight', wev 'equity weight', wcv 'capacity weight' ;
Binary Variable    yy(i,t) 'compliance indicator' ;

Equations eobj, ewsum, ecomp(i,t) ;
eobj..        zobj =e= sum((i,t), yy(i,t));
ewsum..       wmv + wev + wcv =e= 1;
ecomp(i,t)..  emis(i,t) - ( wmv*mA(i) + wev*eA(i) + wcv*cA(i) ) =l= Mbig*(1 - yy(i,t));

Model optw 'weight optimiser' / eobj, ewsum, ecomp / ;

* option optcr = 0;
* solve optw using mip maximizing zobj;
* display wmv.l, wev.l, wcv.l, zobj.l;

* End of file.
