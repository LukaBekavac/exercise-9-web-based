// acting agent

/* Initial beliefs and rules */
degrees(Celcius) :- temperature(Celcius)[source(Agent)] & p(Value,Agent).

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.broadcast(askOne,certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating) );
	.print("Hello world!").

/* 
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName
*/
@organization_deployed_plan
+organization_deployed(OrgName) : true <- 
	.print("Notified about organization deployment of ", OrgName);

	// joins the workspace
	joinWorkspace(OrgName, _);

	// looks up for, and focuses on the OrgArtifact that represents the organization
	lookupArtifact(OrgName, OrgId);
	focus(OrgId).

/* 
 * Plan for reacting to the addition of the belief available_role(Role)
 * Triggering event: addition of belief available_role(Role)
 * Context: true (the plan is always applicable)
 * Body: adopts the role Role
*/
@available_role_plan
+available_role(Role) : true <-
	.print("Adopting the role of ", Role);
	adoptRole(Role).

/* 
 * Plan for reacting to the addition of the belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Triggering event: addition of belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Context: true (the plan is always applicable)
 * Body: prints new interaction trust rating (relevant from Task 1 and on)
*/
+interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating): true <-
	.print("Interaction Trust Rating: (", TargetAgent, ", ", SourceAgent, ", ", MessageContent, ", ", ITRating, ")").

/* 
 * Plan for reacting to the addition of the certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Triggering event: addition of belief certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new certified reputation rating (relevant from Task 3 and on)
*/
+certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating): true <-
	.print("Certified Reputation Rating: (", CertificationAgent, ", ", SourceAgent, ", ", MessageContent, ", ", CRRating, ")").

/* 
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent,, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 5 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating): true <-
	.print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")").

/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celcius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celcius)
 * Context: true (the plan is always applicable)
 * Body: unifies the variable Celcius with the 1st temperature reading from the list TempReadings
*/
@select_reading_task_0_plan
+!select_reading(TempReadings, Celcius) : true <-
    .nth(0, TempReadings, Celcius).

@select_reading_task_0_plan2
+!select_reading_highest_trust(TempReadings, Celcius) : true <-
	// Find all agents that have some trust level
    .findall(Agent, interaction_trust(_, Agent, _, _), Agents);
	
	// Iterate over each agent
	// For task1_2 use !iterate1
	!iterate2(Agents);
	
	// For each agent, find their trust level
	.findall(p(Value, Agent), trust_level(Value, Agent), Result);
	
	// Find the maximum trust level
	.max(Result, Max);
	
	.print("Max: ", Max);
	
	// Add the maximum trust level to the belief base
	+Max;
	
	// Check if Celcius is a degree
	?degrees(Celcius);
	
	// Print the degree in Celsius
	.print("Trusted degree: ", Celcius).


/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celcius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: selects a broadcasted temperature reading. Then, it converts the temperature 
 * from Celcius to binary degrees that are compatible with the movement of the robotic arm. 
 * Finally, it manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature : robot_td(Location) <-

	// creates list TempReadings with all the broadcasted temperature readings
	.findall(TempReading, temperature(TempReading)[source(Ag)], TempReadings);
	.print("Temperature readings to evaluate:", TempReadings);

	// creates goal to select one broadcasted reading to manifest
	//!select_reading(TempReadings, Celcius);

	// creates goal to select highest trusted broadcasted reading to manifest
	!select_reading_highest_trust(TempReadings, Celcius);

	// manifests the selected reading stored in the variable Celcius
	.print("Manifesting temperature (Celcius): ", Celcius);
	convert(Celcius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celcius to binary degress based on the input scale
	.print("Manifesting temperature (moving robotic arm to): ", Degrees);
	
	/* 
	 * If you want to test with the real robotic arm, 
	 * follow the instructions here: https://github.com/HSG-WAS-SS23/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
	 */
	// creates a ThingArtifact based on the TD of the robotic arm
	makeArtifact("leubot1", "wot.ThingArtifact", [Location, true], Leubot1Id); 
	
	// sets the API key for controlling the robotic arm as an authenticated user
	//setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(leubot1)];

	// invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
	invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(leubot1)].

+!iterate1(Agents) : Agents \== [] <-  // If Agents list is not empty
    .nth(0, Agents, Agent0);  // Get the first agent in the list
    .findall(T, interaction_trust(_,Agent0,_,T), LT);  // Find all trust values for Agent0
    .length(LT, LengthLt);  // Get the length of the trust values list
    !sum(LT, SumLt);  // Calculate the sum of the trust values list
    AvgTrust = SumLt / LengthLt;  // Calculate the average trust value
    +trust_level(AvgTrust, Agent0);  // Add the average trust value to the agent's beliefs
    .delete(Agent0, Agents, NewAgents);  // Delete the first agent from the list
    !iterate2(NewAgents).  // Repeat the process with the remaining agents

+!iterate1(Agents) : true <-  // If Agents list is empty
    .print("done").  // Print "done"

+!iterate2(Agents) : Agents \== [] <-  // If Agents list is not empty
    .nth(0, Agents, Agent0);  // Get the first agent in the list
    .findall(T, interaction_trust(_,Agent0,_,T), LT);  // Find all trust values for Agent0
    .findall(W, witness_reputation(_,Agent0,_,W), LW);  // Find all witness reputation values for Agent0
    .length(LT, LengthLt);  // Get the length of the trust values list
    .length(LW, LengthLw);  // Get the length of the witness reputation list
    !sum(LW, SumLw);  // Calculate the sum of the witness reputation list
    !sum(LT, SumLt);  // Calculate the sum of the trust values list
    .findall(C, certified_reputation(_,Agent0,_,C), LC);  // Find all certified reputation values for Agent0
    !sum(LC, SumLc);  // Calculate the sum of the certified reputation list
    .length(LC, LengthLc);  // Get the length of the certified reputation list
    //AvgList = ((SumLt / LengthLt) / 2) + (SumLc / LengthLc) / 2;  // Calculate the average trust value task 3
	AvgList = ((SumLt / LengthLt) / 3) + (SumLc / LengthLc) / 3 + ((SumLw / LengthLw) / 3);  // Calculate the average trust value
    +trust_level(AvgList, Agent0);  // Add the average trust value to the agent's beliefs
    .delete(Agent0, Agents, NewAgents);  // Delete the first agent from the list
    !iterate2(NewAgents).  // Repeat the process with the remaining agents

+!iterate2(Agents) : true <-  // If Agents list is empty
    .print("done").  // Print "done"

// Define a plan to calculate the sum of a list
+!sum(List, Result) : true
  <- !calculate_sum(List, 0, Result).

// Recursive plan to calculate the sum
+!calculate_sum([], Accumulator, Accumulator) : true.

+!calculate_sum([Head|Tail], Accumulator, Result) : true
  <- NewAccumulator = Accumulator + Head;
     !calculate_sum(Tail, NewAccumulator, Result).



/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }

/* Import interaction trust ratings */
{ include("inc/interaction_trust_ratings.asl") }
