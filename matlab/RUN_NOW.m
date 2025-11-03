%% RUN_NOW.m
% Clear cache and run simulation immediately
% This is the QUICKEST way to run the fixed version

fprintf('\n');
fprintf('========================================\n');
fprintf('  Quick Run - Clearing Cache\n');
fprintf('========================================\n\n');

clear all
close all
clear functions
rehash toolboxcache

fprintf('Cache cleared. Starting simulation...\n\n');

run_demo
