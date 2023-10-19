# Shield_Dragon
Natural Selection through a Children's Game

_Introduction_

Shield and Dragon is a rather unique high energy children's game.
Each player is assigned or chooses another player to be their "shield" and another player to be their "dragon".
During play, which lasts for some random interval of time, players attempt to from their dragon from behind their
shield. When play ends, any player who is not safely hidden from their dragon's line of sight is eliminated.
This is usally high chaotic and tends to lead to rotational behavior of the group at large, sometimes
small satillete groups form as well.

I was interested in seeing this happen on a large scale and discover what strategy is most effective.
This simulator can confomrably run about 1000 players or more in a game of Shield and Dragon. "Players" in simulation
are simplified to circles with variable radius, mass, and targetting behavior that collide with one another.

With just a few seconds of simulation, beautiful patterns start to emerge, similar to flocks of starlings
darting through the sky. Often a group will collapse into small crossing loops, which with time sort themselves out into
larger spinning circles. Other times a chance assignment and configuration will create translating groups that
flee from the center with startling speed. With some clever manipulations of shield and dragon assignments,
other interesting arrangements can be made, such as steering the entire group as a whole with
common dragon and shield assignments.

At any moment the simulation can be paused, and all players evaluated for safety. All unsafe players can then be culled,
and a whole new generation created by crossing properties of the surviors. With some room for mutation, this applies a
selective pressure that tends to produce faster and smaller players that stick tightly to their shield players.
This changes the emergent behavior as a whole to become more responsive and rapidly evolving.

_Controls_

Mouse: Move the screen, zoom in and out, select various players 
C: Deselect current selected actor
Space: Start and stop simulation time
P: Generate a normally distributed random population evenly spread across the viewport
R: Remove all players
X: Remove all players who are not safe
G: Generate back up to population size by crossing exisiting player properties
S: Shuffle player shield and dragon assignments randomly
Z: Flip player shield and dragon assignments
Q: Toggle auto generation mode

_Modes_
K: Hold and click players to selectively remove them

M: Hold and click the screen to generate discrete player (up and down arrows for more placed per click)

D: Hold while a player is selected and select another to assign its dragon

B: Hold while a player is selected and select another to assign its shield

A: Hold while using Shield Assignment or D








