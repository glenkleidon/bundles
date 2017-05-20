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

   If you can *_Clone and Compile_* on a clean delphi installation, you have a Project Bundle

Obviously the corollary of this is that:

   If you can't *_Clone and Compile_* on a clean delphi installation, you *dont* have a Project Bundle  

## What are the Issues Project Bundling Solves?

### The Delphi Component Package Approach is a Double Edge Sword
 + Great for the first time use, but troublesome for collaboration 
 + Package approach generally prevents more than one version being loaded at a time
 + Package interdependencies compound the problem above
 + Upgrading a component makes it hard to support earlier released versions
 + GetIt Package installer in the latest BDS helps find packages but does not help to reduce the problem
 
### Component Installation Hampers Produtivity and Mobility
Most projects take hours or days to get set up, so:
  + You cant just buy a new computer without accepting that you will loose days of productivity
  + New developers can't be productive for several days (particular problem for consultants)
  + In corporate environments, the solution to a PC maintenance issues are typically to re-image the PC and developer is reluctant to do that.
  + Using installers means you need admin privileges which is a problem in corporate environments. Either a domain admin has to:
    + provide local administrator access
    + Log in as administrator, install all the components and then use a tool to copy the configuration to the developers account
    + Have the developer install the tools and then type in the password every time the installer prompts
 
 Project Bundling eliminates all of these issues
 
## Project Bundling Guidelines
There are only a few basic guidelines for project bundling, and these you are probably doing already.  However the key is to 
all of these techniques in your project and to make use of a distributed version control system like GIT or Mercurial.

### Rules 
1. Use Distributed Version control repository to hold your project
2. The repository should hold everything you need to build the project
3. Do not use the library path for anything else but out of the box Delphi libraries
4. Don’t _ever_ use static file paths. Use relative paths and environment variables 
5. Must Include the components in your repository (but limit to what is required)
6. Do not install packages in the IDE - Manage them inside the bundle

# Bundle Project Library Template
This repository contains a Project Library Template for Delphi which will create and help maintain a project bundle structure.
It is basically a poor mans answer to a package manager for Delphi.  The concept is simliar to that of NPM for NodeJS in that it helps prepare the way if the project has not been used on this particular installation before.  Unlike NPM though, it prepares the IDE for use with a project rather than collects what is required by the project definition.

## Installing the bundle.
1. Download or clone this repository
2. Copy the Contents of "TemplateLibraries" into a sensible Location for your version of Delphi (say Documents/Embarcadero/templatelibraries or Documents/Delphi/projectTemplates)
3. In Pre-BDS versions of Delphi open the Project and then click Project-->Add to Repository. Fill in the title and description and select the Project Page.
4. In BDS Click Tools-->Template Libraries, select ADD and then browse to the ProjectBundle.bdstemplatelib file and click Open. 

Project bundles will then be available from the New Projects menu (or for pre BDS,  New-->other-->Projects)

## Using Project Bundles.







