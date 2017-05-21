# Project Bundling for Delphi
## Solving the big Delphi productivity issues.

Project Bundles are a way to eliminate the major Delphi productivity and
portability issues.

It is simply an approach to use to increase productivity and developer collaboration 
by defining a set of simple rules to follow when creating a distrubuted version
control repository for delphi Project Groups  (AKA "Delphi Solutions")

To help with this the Project Template included in this repository can automate
the creation and maintenance of you bundle structure.

## The golden rule of Project Bundling

> _If you can **Clone and Compile** on a clean delphi installation, you have a Project Bundle_

Obviously the corollary of this is that:

> _If you can't **Clone and Compile** on a clean delphi installation, you *dont* have a Project Bundle_

## What are the Issues Project Bundling Solves?

### The Delphi Component Package Approach is a Double Edge Sword
 + Great for the first time use, but troublesome for collaborating with team members 
 + Package approach generally prevents more than one version being loaded at a time
 + Package interdependencies compound the problem above
 + Upgrading a component makes it hard to support earlier released versions
 + GetIt Package installer in the latest BDS helps find packages but does not help to reduce the problem
 
### Component Installation Hampers Productivity and Mobility
Even simple projects with only a few components installed can take hours or days to get set up in a new environment.  
This makes it hard to simply get the project and start working on it on a different computer from which it was originally created.
This is troublesome for a singled developer, but a disater in a team or corporate environment

So it means that:
  + You cant just buy a new computer without accepting that you will loose days of productivity
  + New developers can be unproductive for days or even weeks (particular problem for consultants)
  + In corporate environments, the solution to PC maintenance issues is often to re-image the PC.  The Developer has so much invested 
  in the configuration that they are reluctant to do that.
  + Using installers means you need admin privileges which is a problem in corporate environments. A domain admin has to:
    + provide local administrator access; OR
    + Log in as administrator, install all the components and then use a tool to copy the configuration to the developers account; OR
    + Have the developer install the tools and then type in the password every time the installer prompts
 
 Project Bundling helps to eliminate all of these issues.
 
## Project Bundling Guidelines
There are only a few basic guidelines for project bundling, and these you are probably doing already.  However the key is to 
all of these techniques in your project and to make use of a distributed version control system like GIT or Mercurial to bind it all together.

### Rules 
1. Use Distributed Version control repository to hold your project
2. The repository _*MUST*_ hold everything you need to build the project. 
 Include ALL the components in your repository but limit to the BPL and DCU files (and if required, the DFM and RES files) for *each* version of Delphi you want to support. In some cases, the source for the components may be helpful, but avoid if possible.
3. _*ALWAYS *_ create a project Group.
3. Do not use the library path for anything else but out-of-the-box Delphi libraries.
  Use the Project Search Path and Debug path instead
4. Don’t _*ever*_ use static file paths. Use _*only*_ _relative paths_
5. Define _environment variables_ to describe the bundle folders, delphi versions, and component paths.
  Use a batch file to set environment and start the ide in combination with MS Build features in the DPROJ file.
5. Do not _install packages_ in the IDE - Manage them inside the bundle.

Always remember to maintain a separate "Components" repository to "escrow" your component sets and licenses.

# Bundle Project Library Template
This repository contains a Project Library Template for Delphi which will create and help maintain a project bundle structure.
This project template basically creates a poor mans answer to a package manager for Delphi.  The concept is simliar to that of NPM for NodeJS in that it helps prepare the way for a project if it has not been used on this particular installation before and helps maintain it if things change.  Unlike NPM though, it prepares the IDE for use with a project rather than collects what is required by the project definition.

A demonstration of a bundled repo is located at [Demo Bundle](https://github.com/glenkleidon/bundleDemo)

## Installing the bundle.
1. Download or clone this repository
2. Copy the Contents of "TemplateLibraries" into a sensible Location for your version of Delphi (say Documents/Embarcadero/templatelibraries or Documents/Delphi/projectTemplates)
3. Add the Template to Delphi
  + In Pre-BDS versions of Delphi open the CheckBundle Project and then click Project-->Add to Repository. Fill in the title and description and select the Project Page.
  + In BDS Click Tools-->Template Libraries, select ADD and then browse to the ProjectBundle.bdstemplatelib file and click Open. 

Project bundles will then be available from the New Projects menu (or for pre BDS,  New-->other-->Projects)

## Using Project Bundles.
1. Create a new Bundle Project allocating the folder you want to use.
2. Run the checkBundle Project once.  That will initialise the folder and remove the checkbundle source from the project folder.
3. Now use New-Project and create a project making sure you save the project into the correct folder in the bundle
4. Save your Project _and Group_
5. Optionally remove the CheckBundle project from the group
6. Close the IDE
7. Locate the StartProject.bat and update the group name replacing the "CHANGE_ME_IN_THE_STARTPROJECT_BAT" 
8. Make a shortcut to the startProject on your desktop (if desired).
9. Initialise the Bundled folder as Project Repository for Git/Hg as desired and and remove any Ignore Files you do not need
9. Start Delphi using the Shortcut to StartProject.bat or by using the terminal window 

## Delphi Versions and the Bundle Folder structure
--tba
## Adding Components
--tba









